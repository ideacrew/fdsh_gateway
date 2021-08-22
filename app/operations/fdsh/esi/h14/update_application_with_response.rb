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

        def check_esi_mec_eligibility(applicant_hash, esi_applicant_response)
          esi_response_hash = esi_response_params(esi_applicant_response)
          applicant = applicant_entity(applicant_hash)

          esi_eligibility_indicator = esi_response_hash[:esi_eligibility_indicator]
          esi_insured_indicator = esi_response_hash[:esi_insured_indicator]
          esi_inconsistency_indicator = esi_response_hash[:esi_inconsistency_indicator]

          applicant_is_esi_eligible = applicant.esi_eligible?
          applicant_is_esi_enrolled = applicant.esi_enrolled?
          esi_evidence = applicant.esi_evidence

          return if esi_inconsistency_indicator

          unless (applicant_is_esi_eligible == false && applicant_is_esi_enrolled == false) && (esi_eligibility_indicator || esi_insured_indicator)
            return
          end

          # updated_esi_evidence = if (applicant_is_esi_eligible == esi_eligibility_indicator) && (applicant_is_esi_enrolled == esi_insured_indicator)
          #   update_esi_evidence(esi_applicant_response, esi_evidence.to_h, 'verified')
          # else
          #   update_esi_evidence(esi_applicant_response, esi_evidence.to_h, 'outstanding')
          # end
          updated_esi_evidence = update_esi_evidence(esi_applicant_response, esi_evidence.to_h, 'outstanding')
          applicant_hash[:evidences].detect {|e| e[:key] == :esi_mec}.merge!(updated_esi_evidence)
        end

        def applicant_entity(applicant_hash)
          AcaEntities::MagiMedicaid::Applicant.new(applicant_hash)
        end

        def update_esi_evidence(esi_applicant_response, esi_evidence_hash, status)
          eligibility_hash = eligibility_result_hash(esi_applicant_response, status)
          esi_evidence_hash[:eligibility_status] = status
          esi_evidence_hash[:eligibility_results] = [eligibility_hash]
          esi_evidence_hash
        end

        def eligibility_result_hash(esi_applicant_response, status)
          {
            result: (status == 'verified' ? :eligible : :ineligible),
            source: "FDSH",
            code: esi_applicant_response.dig(:ResponseMetadata, :ResponseCode),
            code_description: esi_applicant_response.dig(:ResponseMetadata, :ResponseDescriptionText)
          }
        end

        def build_application(application_hash)
          result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(application_hash)
          result.success? ? result : Failure(result.failure.errors.to_h)
        end

        def update_application(application, esi_response)
          application_hash = application.to_h

          return Success(application_hash) if esi_response.ResponseMetadata.present?

          esi_response_hash = esi_response.to_h
          application_hash[:applicants].each do |applicant_hash|
            esi_applicant_response = find_response_for_applicant(applicant_hash, esi_response_hash)
            next unless esi_applicant_response

            check_esi_mec_eligibility(applicant_hash, esi_applicant_response)
          end

          Success(application_hash)
        end

        def esi_response_params(esi_applicant_response)
          {
            esi_eligibility_indicator: esi_applicant_response.dig(:ApplicantMECInformation, :InsuranceApplicantResponse,
                                                                  :InsuranceApplicantEligibleEmployerSponsoredInsuranceIndicator),
            esi_insured_indicator: esi_applicant_response.dig(:ApplicantMECInformation, :InsuranceApplicantResponse,
                                                              :InsuranceApplicantInsuredIndicator),
            esi_inconsistency_indicator: esi_applicant_response.dig(:ApplicantMECInformation, :InconsistencyIndicator)
          }
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