# frozen_string_literal: true

module Fdsh
  module Esi
    module H14
      # update the request application with the response
      class UpdateApplicationWithResponse
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @return [Dry::Monads::Result]
        def call(application, esi_response)
          updated_application_hash = yield update_application(application, esi_response)
          updated_application = yield build_application(updated_application_hash)

          Success(updated_application)
        end

        protected

        def build_application(_application_hash)
          result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(parsing_result.value!)
          result.success? ? result : Failure(result.failure.errors.to_h)
        end

        def update_application(application, esi_response)
          application_hash = application.to_h

          return application_hash if esi_response.ResponseMetadata.present?

          esi_response_hash = esi_response.to_h
          application_hash[:applicants].each do |applicant|
            esi_applicant_response = find_response_for_applicant(applicant, esi_response_hash)
            next unless esi_applicant_response
            esi_params = {
              esi_eligibility_indicator: esi_applicant_response.dig(:ApplicantMECInformation, :InsuranceApplicantResponse,
                                                                    :InsuranceApplicantEligibleEmployerSponsoredInsuranceIndicator),
              esi_insured_indicator: esi_applicant_response.dig(:ApplicantMECInformation, :InsuranceApplicantResponse,
                                                                :InsuranceApplicantInsuredIndicator),
              esi_inconsistency_indicator: esi_applicant_response.dig(:ApplicantMECInformation, :InconsistencyIndicator)
            }

            applcant.merge!(esi_params)
          end

          Success(application_hash)
        end

        def find_response_for_applicant(applicant, esi_response)
          esi_response[:ApplicantResponseSet][:ApplicantResponses].detect do |applicant_response|
            ssn = applicant_response.dig(:ResponsePerson, :PersonSSNIdentification, :IdentificationID)
            applicant[:identifying_information][:ssn] == ssn
          end
        end
      end
    end
  end
end