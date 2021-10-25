# frozen_string_literal: true

module Fdsh
  module Rrv
    module Medicare
      # This class takes AcaEntities::MagiMedicaid::Application as input and returns the Esi Mec request hash.
      class TransformApplicationToRrvMedicareRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @option params [AcaEntities::MagiMedicaid::Application] :Applicattion
        # @return [Dry::Monads::Result]
        def call(applications)
          validated_applications = yield validate_applications(applications)
          _updated_transaction = yield store_request(validated_applications)
          request_entity = yield build_request_entity(validated_applications)

          Success(request_entity)
        end

        def build_application(application_hash)
          result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(application_hash)
          result.success? ? result : Failure(result.failure.errors.to_h)
        end

        # Validate input object
        def validate_applications(applications)
          valid_applications = []
          applications.each do |application|
            if application.is_a?(::AcaEntities::MagiMedicaid::Application)
              valid_applications << application
            else
              result = build_application(application)
              valid_applications << result.value! if parsed_result.success?
            end
          end

          Success(valid_applications)
        end

        # Transform application params To BuildMedicareRequest Contract params
        def build_request_entity(applications)
          ::AcaEntities::Fdsh::Rrv::Medicare::Operations::BuildMedicareRequest.new.call(applications)
        end

        def store_request(applications)
          applications.each do |application|
            application.applicants.each do |applicant|
              create_or_update_transaction("request", application, applicant)
            end
          end
          Success(true)
        end

        def create_or_update_transaction(key, value, applicant)
          activity_hash = {
            correlation_id: "rrv_mdcr_#{applicant.identifying_information.encrypted_ssn}",
            command: "Fdsh::Rrv::Medicare::BuildMedicareRequestXml",
            event_key: "rrv_mdcr_determination_requested",
            message: { "#{key}": value.to_h }
          }

          transaction_hash = { correlation_id: activity_hash[:correlation_id], magi_medicaid_application: value.to_json,
                               activity: activity_hash }
          Try do
            Journal::Transactions::AddActivity.new.call(transaction_hash)
          end
        end
      end
    end
  end
end
