# frozen_string_literal: true

module Fdsh
    module Rrv
      module Medicare
        module Request
          # This class takes application hash as input and returns ::AcaEntities::MagiMedicaid::Application entity.
          class StoreApplicationRrvRequest
            include Dry::Monads[:result, :do, :try]
            include EventSource::Command

            # @option params [Hash] :Applicattion
            # @return [Dry::Monads::Result] AcaEntities::MagiMedicaid::Application
            def call(params)
              values               = yield validate(params)
              application          = yield validate_application(values)
              _updated_transaction = yield store_request(application)

              Success(application)
            end

            private

            def validate(params)
              return Failure('application is missing') unless params[:application_hash]
              Success(params)
            end

            def validate_application(values)
              result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(values[:application_hash])
              result.success? ? result : Failure(result.failure.errors.to_h)
            end

            def store_request(application)
              application.applicants.each do |applicant|
                create_or_update_transaction("request", application, applicant)
              end

              Success(true)
            end

            def create_or_update_transaction(key, value, applicant)
              activity_hash = {
                correlation_id: "rrv_mdcr_#{applicant.identifying_information.encrypted_ssn}",
                command: "Fdsh::Rrv::Medicare::BuildMedicareRequestXml",
                event_key: "rrv_mdcr_determination_requested",
                message: { "#{key}": value.to_json },
                assistance_year: value.assistance_year
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
  end
  