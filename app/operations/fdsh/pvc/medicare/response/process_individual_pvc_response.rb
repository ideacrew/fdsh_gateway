# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'digest'
require 'zip'

module Fdsh
  module Pvc
    module Medicare
      module Response
        # This class processes individual pvc responses
        class ProcessIndividualPvcResponse
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          def call(response)
            response_values = yield validate(response)
            individual_response = yield create_response_entity(response_values)
            output = yield determine_individual_response(individual_response)

            Success(output)
          end

          private

          def validate(response)
            result = AcaEntities::Fdsh::Pvc::Medicare::IndividualResponseContract.new.call(response)
            if result.success?
              Success(result)
            else
              Failure("Invalid response, #{result.errors.to_h}")
            end
          end

          def create_response_entity(response_values)
            entity = AcaEntities::Fdsh::Pvc::Medicare::IndividualResponse.new(response_values.to_h)

            Success(entity)
          end

          def determine_individual_response(individual_response)
            person_ssn = individual_response.PersonSSNIdentification
            encrypted_ssn = encrypt(person_ssn)
            @transaction = ::Transaction.where(correlation_id: "pvc_mdcr_#{encrypted_ssn}").max_by(&:created_at)
            return Failure("Unable to find transaction with correlation_id: pvc_mdcr_#{encrypted_ssn}") unless @transaction.present?
            store_response(individual_response)
            application_entity = fetch_application_from_transaction(@transaction.magi_medicaid_application)
            application_hash, applicant = determine_medicare_eligibility(individual_response, application_entity)
            if applicant
              publish(application_hash, application_hash[:hbx_id], applicant[:person_hbx_id])
              Success(application_hash)
            else
              Failure("Unable to publish event due to applicant not present or non esi evidence missing for pvc_mdcr_#{encrypted_ssn}")
            end
          end

          def fetch_applicant(encrypted_ssn, applicant_hash)
            applicant_hash[:identifying_information][:encrypted_ssn] == encrypted_ssn ? applicant_hash : nil
          end

          def find_applicant_matching_response(individual_response, application)
            encrypted_ssn = encrypt(individual_response.PersonSSNIdentification)
            application[:applicants].detect {|applicant| fetch_applicant(encrypted_ssn, applicant) }
          end

          def determine_medicare_eligibility(individual_response, application)
            application_hash = application.to_h
            applicant = find_applicant_matching_response(individual_response, application_hash)

            return [application_hash, false] unless applicant

            applicant_entity = applicant_entity(applicant)
            non_esi_evidence = applicant_entity&.non_esi_evidence&.to_h

            return [application_hash, false] unless non_esi_evidence

            status = determine_medicare_status(individual_response, applicant_entity, application.aptc_effective_date&.to_date)
            updated_non_esi_evidence = update_non_esi_evidence(non_esi_evidence, status, individual_response)
            applicant[:non_esi_evidence].merge!(updated_non_esi_evidence)

            [application_hash, applicant]
          end

          def fetch_application_from_transaction(application)
            application_string = application

            parsing_result = Try do
              JSON.parse(application_string, :symbolize_names => true)
            end

            AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(parsing_result.value!).value!
          end

          def store_response(individual_response)
            activity_hash = {
              correlation_id: "pvc_mdcr_#{encrypt(individual_response.PersonSSNIdentification)}",
              command: "Fdsh::Pvc::Medicare::ProcessPvcMedicareDetermination",
              event_key: "pvc_mdcr_determination_determined",
              message: { response: individual_response.to_h }
            }
            @transaction.activities << Activity.new(activity_hash)
          end

          def encrypt(value)
            AcaEntities::Operations::Encryption::Encrypt.new.call({ value: value }).value!
          end

          def applicant_entity(applicant_hash)
            AcaEntities::MagiMedicaid::Applicant.new(applicant_hash)
          end

          def update_non_esi_evidence(non_esi_evidence_hash, status, individual_response)
            request_result = request_result_hash(individual_response.to_h, status)
            non_esi_evidence_hash[:aasm_state] = status
            non_esi_evidence_hash[:request_results] = [request_result]
            non_esi_evidence_hash
          end

          def request_result_hash(individual_response, status)
            {
              result: status,
              source: "FDSH",
              action: 'pvc_bulk_call',
              source_transaction_id: @transaction&.id.to_s,
              code: individual_response&.dig(:ResponseMetadata, :ResponseCode),
              code_description: individual_response&.dig(:ResponseMetadata, :ResponseDescriptionText),
              raw_payload: individual_response.to_json
            }
          end

          def response_in_application_date_range?(start_on, end_on, application_effective_on)
            if start_on.present? && end_on.present?
              return true if start_on > application_effective_on
              return true if end_on < application_effective_on
              false
            elsif start_on.present?
              return true if start_on > application_effective_on
              false
            elsif end_on.present?
              return true if end_on < application_effective_on
              false
            else
              true
            end
          end

          def determine_medicare_status(individual_response, applicant, application_effective_on)
            insurance_effective_date = individual_response.Insurances&.first&.InsuranceEffectiveDate&.to_date
            insurance_end_date = individual_response.Insurances&.first&.InsuranceEndDate&.to_date
            benefits = applicant.health_benefits_for("medicare")
            return 'attested' if benefits

            date_range_satisfied = response_in_application_date_range?(insurance_effective_date, insurance_end_date, application_effective_on)
            date_range_satisfied ? "attested" : "outstanding"
          end

          def publish(application, request_id, applicant_person_hbx_id)
            payload = application.to_h
            event = event('events.fdsh.pvc.periodic_verification_confirmation_determined',
                          attributes: { payload: payload, applicant_identifier: applicant_person_hbx_id },
                          headers: { correlation_id: request_id }).value!
            event.publish
          end
        end
      end
    end
  end
end
