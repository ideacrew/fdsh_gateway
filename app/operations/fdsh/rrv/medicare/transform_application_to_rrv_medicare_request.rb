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
          _updated_transaction = yield store_request(applications)
          request_entity = yield build_request_entity(applications)

          Success(request_entity)
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

          application_id = value.hbx_id
          primary_hbx_id = value.applicants.detect(&:is_primary_applicant)&.person_hbx_id
          transaction_hash = {
            correlation_id: activity_hash[:correlation_id],
            activity: activity_hash,
            magi_medicaid_application: value.to_json,
            application_id: application_id,
            primary_hbx_id: primary_hbx_id
          }
          Try do
            Journal::Transactions::AddActivity.new.call(transaction_hash)
          end
        end
      end
    end
  end
end
