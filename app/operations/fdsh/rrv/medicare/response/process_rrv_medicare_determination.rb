# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'digest'
require 'zip'

module Fdsh
  module Rrv
    module Medicare
      module Response
        # This class create a rrv medicare request manifest file
        class ProcessRrvMedicareDetermination
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          # @param opts [Hash] the parameters to construct medicare response
          # @option opts [Hash] criterion required
          def call(medicare_response)
            determine_individual_response(medicare_response)
            Success(true)
          end

          private

          def determine_individual_response(medicare_response)
            medicare_response.IndividualResponses.each do |individual_response|
              person_ssn = individual_response.PersonSSNIdentification
              next unless person_ssn.present?
              encrypted_ssn = encrypt(person_ssn)
              @transaction = ::Transaction.where(correlation_id: "rrv_mdcr_#{encrypted_ssn}").first
              store_response(individual_response)
              application_entity = fetch_application_from_transaction(@transaction.magi_medicaid_application)
              application_hash = determine_medicare_eligibility(individual_response, application_entity)
              publish(application_hash, application_hash[:hbx_id])
            end
          end

          def determine_medicare_eligibility(individual_response, application)
            application_hash = application.to_h
            application_hash[:applicants].each do |applicant_hash|
              encrypted_ssn = encrypt(individual_response.PersonSSNIdentification)
              applicant = fetch_applicant(encrypted_ssn, applicant_hash)
              next if applicant.blank?
              applicant_entity = applicant_entity(applicant)
              non_esi_evidence = applicant_entity&.non_esi_evidence&.to_h
              next if non_esi_evidence.blank?
              status = determine_medicare_status(individual_response, applicant_entity)
              updated_non_esi_evidence = update_non_esi_evidence(non_esi_evidence, status)
              applicant_hash[:non_esi_evidence].merge!(updated_non_esi_evidence)
            end
            application_hash
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
              correlation_id: "rrv_mdcr_#{encrypt(individual_response.PersonSSNIdentification)}",
              command: "Fdsh::Rrv::Medicare::ProcessRrvMedicareDetermination",
              event_key: "rrv_mdcr_determination_determined",
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

          def fetch_applicant(encrypted_ssn, applicant_hash)
            applicant_hash[:identifying_information][:encrypted_ssn] == encrypted_ssn ? applicant_hash : nil
          end

          def update_non_esi_evidence(non_esi_evidence_hash,  status)
            request_result = request_result_hash(non_esi_evidence_hash, status)
            non_esi_evidence_hash[:aasm_state] = status
            non_esi_evidence_hash[:request_results] = [request_result]
            non_esi_evidence_hash
          end

          def request_result_hash(non_esi_applicant_response, status)
            {
              result: status,
              source: "FDSH",
              source_transaction_id: @transaction&.id.to_s,
              code: non_esi_applicant_response&.dig(:ResponseMetadata, :ResponseCode),
              code_description: non_esi_applicant_response&.dig(:ResponseMetadata, :ResponseDescriptionText),
              raw_payload: non_esi_applicant_response.to_json
            }
          end

          def determine_medicare_status(individual_response, applicant)
            insurance_effective_date = individual_response.Insurances&.first&.InsuranceEffectiveDate
            insurance_end_date = individual_response.Insurances&.first&.InsuranceEndDate
            benefits = applicant.health_benefits_for("medicare")
            benefits == false && (insurance_effective_date.present? || insurance_end_date.present?) ? "outstanding" : "attested"
          end

          def publish(application, request_id)
            payload = application.to_h
            event = event('events.fdsh.renewal_eligibilities.magi_medicaid_application_renewal_eligibilities_medicare_determined',
                          attributes: payload,
                          headers: { correlation_id: request_id }).value!
            event.publish
          end
        end
      end
    end
  end
end
