# frozen_string_literal: true

module Fdsh
  module H36
    module Request
      # BuildH36Request
      class BuildH36Xml
        include Dry::Monads[:result, :do, :try]

        TOTAL_CALENDAR_MONTHS = 12

        def call(params)
          values        = yield validate(params)
          irs_group     = yield fetch_subject(values[:transaction_id])
          family_hash   = yield validate_family_json_hash(irs_group)
          family_entity = yield build_family_entity(family_hash)
          payload       = yield build_h36_family_payload(values, family_entity)
          h36_payload   = yield validate_payload(payload)
          h36_request   = yield h36_request_entity(h36_payload)
          xml_string    = yield encode_xml_and_schema_validate(h36_request)
          h36_xml       = yield encode_request_xml(xml_string)
          result        = yield persist_xml_on_irs_group(irs_group, h36_xml)

          Success(result)
        end

        private

        def validate(params)
          errors = []
          errors << "transaction_id required" unless params[:transaction_id]
          errors << "transmission_id required" unless params[:transmission_id]
          errors << "assistance_year required" unless params[:assistance_year]
          errors << "month_of_year required" unless params[:month_of_year]

          errors.empty? ? Success(params) : Failure(errors)
        end

        def fetch_subject(transaction_id)
          @transaction = ::Transmittable::Transaction.find(transaction_id)
          result = @transaction.transactable
          return Failure("Unable to find transaction with id #{transaction_id}") if result.blank?

          Success(result)
        end

        def validate_family_json_hash(irs_group)
          family_hash = JSON.parse(irs_group.family_cv, symbolize_names: true)
          validation_result = AcaEntities::Contracts::Families::FamilyContract.new.call(family_hash)
          validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
        end

        def build_family_entity(family_hash)
          result = Try do
            AcaEntities::Families::Family.new(family_hash)
          end

          result.or do |e|
            Failure(e)
          end
        end

        def build_h36_family_payload(values, family)
          @max_month = values[:month_of_year] > TOTAL_CALENDAR_MONTHS ? TOTAL_CALENDAR_MONTHS : values[:month_of_year]
          @assistance_year = values[:assistance_year]
          insurance_agreements = family.households.flat_map(&:insurance_agreements)
          valid_agreements = insurance_agreements.select do |agreement|
            agreement.plan_year.to_s == @assistance_year.to_s
          end

          insurance_policies = valid_agreements.flat_map(&:insurance_policies)
          contract_holder = insurance_agreements.first.contract_holder
          other_relevant_adult = fetch_other_relevant_adult(family, contract_holder)
          valid_policies = insurance_policies.reject do |policy|
            non_eligible_policy?(policy)
          end

          if valid_policies.blank?
            record_denial("No valid policies exists")
            return Failure("No valid policies exist")
          end

          result = construct_payload(family, other_relevant_adult, valid_policies)
          Success(result)
        rescue StandardError => e
          record_exception({ build_h36_payload: e.to_s })
        end

        def construct_payload(family, other_relevant_adult, valid_policies)
          {
            SubmissionYr: Date.today.year.to_s,
            SubmissionMonthNum: Date.today.month.to_s,
            ApplicableCoverageYr: @assistance_year.to_s,
            IndividualExchange: {
              HealthExchangeId: "02.ME*.SBE.001.001",
              IrsHouseholdGroup: {
                IrsGroupIdentificationNumber: family.irs_group_id,
                TaxHouseholds: construct_tax_households(other_relevant_adult, valid_policies, family).flatten.compact,
                InsurancePolicies: construct_insurance_policies(valid_policies).flatten.compact
              }
            }
          }
        end

        def non_eligible_policy?(policy)
          return true if policy.aptc_csr_tax_households.blank?
          return true if policy.aasm_state == "canceled"
          return true if policy.insurance_product.coverage_type == 'dental'
          return true if policy.insurance_product.metal_level == 'catastrophic'
          return true if policy.carrier_policy_id.blank?
          return true if policy.start_on.year.to_s != @assistance_year.to_s

          false
        end

        def fetch_other_relevant_adult(family, contract_holder)
          family.family_members.detect do |fm_member|
            fm_member.person.hbx_id == contract_holder.hbx_id
          end
        end

        def construct_tax_households(other_relevant_adult, insurance_policies, family)
          result = BuildH36TaxHouseholdsPayload.new.call({ family: family,
                                                           other_relevant_adult: other_relevant_adult,
                                                           insurance_policies: insurance_policies,
                                                           max_month: @max_month })

          if result.success?
            result.success
          else
            result.failure
          end
        end

        def construct_insurance_policies(insurance_policies)
          result = BuildH36InsurancePoliciesPayload.new.call({ insurance_policies: insurance_policies,
                                                               max_month: @max_month })
          if result.success?
            result.success
          else
            result.failure
          end
        end

        def validate_payload(payload)
          result = AcaEntities::Fdsh::H36::Contracts::HealthExchangeContract.new.call(payload)
          result.success? ? Success(result) : Failure("Invalid H36 request due to #{result.errors.to_h}")
        end

        def h36_request_entity(payload)
          Success(AcaEntities::Fdsh::H36::HealthExchange.new(payload.to_h))
        end

        def encode_xml_and_schema_validate(payload)
          xml_string = ::AcaEntities::Serializers::Xml::Fdsh::H36::HealthExchange.domain_to_mapper(payload).to_xml
          sanitized_xml = ::Fdsh::H36::Transmissions::XmlSanitizer.new.call(xml_string: xml_string).success
          build_result = AcaEntities::Serializers::Xml::Fdsh::H36::Operations::ValidateH36RequestPayloadXml.new.call(sanitized_xml)

          if build_result.success?
            Success(sanitized_xml)
          else
            record_exception({ transaction_xml: error_messages(build_result) })
            Failure("Invalid H41 xml due to #{build_result.failure}")
          end
        end

        def record_exception(error_message)
          @transaction.status = :errored
          @transaction.transmit_action = :no_transmit
          @transaction.transaction_errors = { h36: error_message }
          @transaction.save
        end

        def record_denial(message)
          @transaction.status = :denied
          @transaction.transmit_action = :no_transmit
          @transaction.transaction_errors = { h36: message }
          @transaction.save
        end

        def error_messages(build_result)
          if build_result.failure.is_a?(Dry::Validation::Result)
            build_result.failure.errors.to_h
          else
            build_result.failure
          end
        end

        def encode_request_xml(xml_string)
          encoding_result = Try do
            xml_doc = Nokogiri::XML(xml_string)
            xml_doc.to_xml(:indent => 2, :encoding => 'UTF-8')
          end

          encoding_result.or do |e|
            Failure(e)
          end
        end

        def persist_xml_on_irs_group(irs_group, h36_xml)
          irs_group.update!(transaction_xml: h36_xml)
          Success(irs_group)
        end
      end
    end
  end
end