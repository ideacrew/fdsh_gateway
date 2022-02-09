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
              next unless @transaction.present?
              store_response(individual_response)
              application_entity = fetch_application_from_transaction(@transaction.magi_medicaid_application)
              application_hash, applicant = determine_medicare_eligibility(individual_response, application_entity)
              publish(application_hash, application_hash[:hbx_id], applicant[:person_hbx_id]) if applicant
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
            event = event('events.fdsh.renewal_eligibilities.magi_medicaid_application_renewal_eligibilities_medicare_determined',
                          attributes: { payload: payload, applicant_identifier: applicant_person_hbx_id },
                          headers: { correlation_id: request_id }).value!
            event.publish
          end
        end
      end
    end
  end
end
