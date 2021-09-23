# frozen_string_literal: true

module Fdsh
  module Rrv
    module Medicare
      # This class takes AcaEntities::MagiMedicaid::Application as input and returns the Esi Mec request hash.
      class TransformApplicationToRrvMedicareRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param params [Hash] The params to execute an FDSH SSA Composite Verification Request
        # @option params [AcaEntities::MagiMedicaid::Application] :Applicattion
        # @return [Dry::Monads::Result]
        def call(applications)
          _validated_application = yield validate_application(applications)
          _updated_transaction = yield store_request(applications)
          request_entity = yield build_request_entity(applications)

          Success(request_entity)
        end

        # Validate input object
        def validate_application(applications)
          results = applications.collect do |application|
            next if application.is_a?(::AcaEntities::MagiMedicaid::Application)
            Failure(
              "Invalid application, given value is not a ::AcaEntities::MagiMedicaid::Application, input_value:#{application}"
            )
          end
          results.compact.present? ? Failure("Invalid applications present") : Success(true)
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
            correlation_id: "rrv_mdcr_#{applicant.identifying_information.ssn}",
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
