# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Pvc
    module Medicare
      module Request
        # This class stores a pdm request and manifest
        class StoreRequest
          include Dry::Monads[:result, :do, :try]

          def call(params)
            application = yield validate_and_fetch_application(params)
            _updated_transaction = yield store_request(application)

            Success(application)
          end

          private

          def validate_and_fetch_application(params)
            errors = []
            errors << 'application is missing' unless params[:application_hash]

            result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(params[:application_hash])
            if result.success?
              result
            else
              errors << result.failure.errors.to_h
              Failure[errors]
            end
          end

          def store_request(application)
            application.applicants.each do |applicant|
              next unless applicant.identifying_information.encrypted_ssn.present?

              create_or_update_transaction("request", application, applicant)
            end

            Success(true)
          end

          def create_or_update_transaction(key, value, applicant)
            activity_hash = {
              correlation_id: "pvc_mdcr_#{applicant.identifying_information.encrypted_ssn}",
              command: "Fdsh::Pvc::Medicare::Request::StoreRequest",
              event_key: "pvc_mdcr_determination_requested",
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
