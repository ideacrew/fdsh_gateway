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
            # validate
            validated_params = yield validate(params)
            # save request
            save_request(validated_params)
          end

          def validate(params)
            errors = []
            errors << 'applicant missing' unless params[:applicant]
            errors << 'manifest missing' unless params[:manifest]
            errors << 'application hbx id missing' unless params[:application_hbx_id]
            result_manifest = ::AcaEntities::Pdm::Contracts::ManifestContract.new.call(params[:manifest])
            result_applicant = ::AcaEntities::MagiMedicaid::Contracts::ApplicantContract.new.call(params[:applicant])

            errors << result_manifest.errors if result_manifest.errors.present?
            errors << result_applicant.errors if result_applicant.errors.present?

            errors.empty? ? Success(params) : Failure(errors)
          end

          def save_request(validated_params)
            request = {
              subject_id: validated_params[:applicant][:identifying_information][:encrypted_ssn],
              command: "medicare",
              request_payload: validated_params[:applicant].to_json,
              document_identifier: { application_hbx_id: validated_params[:application_hbx_id] }
            }
            Pdm::Request::FindOrCreate.new.call(request, validated_params[:manifest])
          end
        end
      end
    end
  end
end
