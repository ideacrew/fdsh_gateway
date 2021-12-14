# frozen_string_literal: true

module Fdsh
  module Esi
    module H14
      # update the request application with the response
      class UpdateApplicationWithResponse
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @return [Dry::Monads::Result]
        def call(application, esi_response, correlation_id)
          updated_application_hash = yield update_application(application, esi_response, correlation_id)
          updated_application = yield build_application(updated_application_hash)

          Success(updated_application)
        end

        protected

        def check_esi_mec_eligibility(applicant_hash, esi_applicant_response, correlation_id)
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

          status = if (applicant_is_esi_eligible == false && applicant_is_esi_enrolled == false) &&
                      (esi_eligibility_indicator || esi_insured_indicator)
                     "outstanding"
                   else
                     "attested"
                   end

          updated_esi_evidence = update_esi_evidence(esi_applicant_response, esi_evidence.to_h, status, correlation_id)
          applicant_hash[:esi_evidence].merge!(updated_esi_evidence)
        end

        def applicant_entity(applicant_hash)
          AcaEntities::MagiMedicaid::Applicant.new(applicant_hash)
        end

        def update_esi_evidence(esi_applicant_response, esi_evidence_hash, status, correlation_id)
          request_result = request_result_hash(esi_applicant_response, status, correlation_id)
          esi_evidence_hash[:aasm_state] = status
          esi_evidence_hash[:request_results] = [request_result]
          esi_evidence_hash
        end

        def request_result_hash(esi_applicant_response, status, correlation_id)
          transaction = Transaction.where(correlation_id: "esi_#{correlation_id}").max_by(&:created_at)
          {
            result: status,
            source: "FDSH",
            source_transaction_id: transaction&.id,
            code: esi_applicant_response&.dig(:ResponseMetadata, :ResponseCode),
            code_description: esi_applicant_response&.dig(:ResponseMetadata, :ResponseDescriptionText),
            raw_payload: esi_applicant_response.to_json
          }
        end

        def build_application(application_hash)
          result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(application_hash)
          result.success? ? result : Failure(result.failure.errors.to_h)
        end

        def update_application(application, esi_response, correlation_id)
          application_hash = application.to_h

          return Success(application_hash) if esi_response.ResponseMetadata.present?

          esi_response_hash = esi_response.to_h
          application_hash[:applicants].each do |applicant_hash|
            esi_applicant_response = find_response_for_applicant(applicant_hash, esi_response_hash)
            next unless esi_applicant_response

            check_esi_mec_eligibility(applicant_hash, esi_applicant_response, correlation_id)
          end

          Success(application_hash)
        end

        def esi_response_params(esi_applicant_response)
          {
            esi_eligibility_indicator: esi_applicant_response&.dig(:ApplicantMECInformation, :InsuranceApplicantResponse,
                                                                   :InsuranceApplicantEligibleEmployerSponsoredInsuranceIndicator),
            esi_insured_indicator: esi_applicant_response&.dig(:ApplicantMECInformation, :InsuranceApplicantResponse,
                                                               :InsuranceApplicantInsuredIndicator),
            esi_inconsistency_indicator: esi_applicant_response&.dig(:ApplicantMECInformation, :InconsistencyIndicator)
          }
        end

        def find_response_for_applicant(applicant, esi_response)
          esi_response[:ApplicantResponseSet][:ApplicantResponses].detect do |applicant_response|
            ssn = applicant_response.dig(:ResponsePerson, :PersonSSNIdentification, :IdentificationID)
            encrypted_ssn = AcaEntities::Operations::Encryption::Encrypt.new.call({ value: ssn }).value!
            applicant[:identifying_information][:encrypted_ssn] == encrypted_ssn
          end
        end
      end
    end
  end
end