# frozen_string_literal: true

module Fdsh
  module NonEsi
    module H31
      # update the request application with the response
      class UpdateApplicationWithResponse
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        BENEFIT_TYPES = [{ MEDI: 'medicare' }, { TRIC: 'tricare' }, { PECO: 'peace_corps_health_benefits' },
                         { VHPC: 'veterans_administration_health_benefits' }].freeze

        # @return [Dry::Monads::Result]
        def call(application, non_esi_response, correlation_id)
          updated_application_hash = yield update_application(application, non_esi_response, correlation_id)
          updated_application = yield build_application(updated_application_hash)

          Success(updated_application)
        end

        protected

        def check_non_esi_mec_eligibility(applicant_hash, applicant_response, correlation_id)
          applicant = applicant_entity(applicant_hash)
          non_esi_evidence = applicant.non_esi_evidence

          eligibility_results = BENEFIT_TYPES.collect do |benefit_type|
            benefit_type.collect do |key, value|
              org_response = organization_response(applicant_response, key.to_s)
              eligibility = org_response&.dig(:MECCoverage, :MECVerificationCode) == 'Y'
              benefits = applicant.health_benefits_for(value)
              status = benefits == false && eligibility == true ? 'outstanding' : 'attested'
              request_result_hash(org_response, status, "FDSH #{key}", correlation_id)
            end
          end.flatten!
          ineligible_status = eligibility_results.any? {|eligibility| eligibility[:result] == 'ineligible'}
          status = ineligible_status ? 'outstanding' : 'attested'
          updated_non_esi_evidence = update_non_esi_evidence(applicant_response, non_esi_evidence.to_h, eligibility_results, status)
          applicant_hash[:non_esi_evidence].merge!(updated_non_esi_evidence)
        end

        def update_non_esi_evidence(_applicant_response, esi_evidence_hash, request_results, status)
          esi_evidence_hash[:aasm_state] = status
          esi_evidence_hash[:request_results] = request_results
          esi_evidence_hash
        end

        def request_result_hash(response, status, source, correlation_id)
          transaction = Transaction.where(correlation_id: "non_esi_#{correlation_id}").max_by(&:created_at)
          {
            result: (status == 'outstanding') ? "ineligible" : 'eligible',
            source: source,
            source_transaction_id: transaction&.id.to_s,
            code: response&.dig(:ResponseMetadata, :ResponseCode),
            code_description: response&.dig(:ResponseMetadata, :ResponseDescriptionText),
            raw_payload: response.to_json
          }
        end

        def build_application(application_hash)
          result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(application_hash)
          result.success? ? result : Failure(result.failure.errors.to_h)
        end

        def failure_response_metadata(application_hash, non_esi_response, correlation_id)
          application_hash[:applicants].each do |applicant_hash|
            applicant = applicant_entity(applicant_hash)
            non_esi_evidence = applicant.non_esi_evidence.to_h
            request_result = request_result_hash(non_esi_response.to_h, 'ineligible', "FDSH NON_ESI", correlation_id)
            non_esi_evidence[:request_results] = [request_result]
            applicant_hash[:non_esi_evidence].merge!(non_esi_evidence)
          end

          Success(application_hash)
        end

        def applicant_entity(applicant_hash)
          AcaEntities::MagiMedicaid::Applicant.new(applicant_hash)
        end

        def update_application(application, non_esi_response, correlation_id)
          application_hash = application.to_h
          return failure_response_metadata(application_hash, non_esi_response, correlation_id) if non_esi_response.ResponseMetadata.present?

          non_esi_response_hash = non_esi_response.to_h
          application_hash[:applicants].each do |applicant_hash|
            non_esi_applicant_response = find_response_for_applicant(applicant_hash, non_esi_response_hash)
            next unless non_esi_applicant_response

            check_non_esi_mec_eligibility(applicant_hash, non_esi_applicant_response, correlation_id)
          end

          Success(application_hash)
        end

        def organization_response(applicant_response, code)
          applicant_response[:OtherCoverages].detect {|coverage| coverage[:OrganizationCode] == code}
        end

        def find_response_for_applicant(applicant, non_esi_response)
          non_esi_response[:IndividualResponseSet][:IndividualResponses].detect do |individual_response|
            ssn = individual_response.dig(:Applicant, :PersonSSNIdentification)
            encrypted_ssn = AcaEntities::Operations::Encryption::Encrypt.new.call({ value: ssn }).value!
            applicant[:identifying_information][:encrypted_ssn] == encrypted_ssn
          end
        end
      end
    end
  end
end