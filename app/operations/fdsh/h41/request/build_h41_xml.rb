# frozen_string_literal: true

module Fdsh
  module H41
    module Request
      # BuildH41Request
      class BuildH41Xml
        include Dry::Monads[:result, :do, :try]

        def call(params)
          values      = yield validate(params)
          payload     = yield build_1095a_payload(values)
          h41_payload = yield validate_payload(payload)
          h41_request = yield h41_request_entity(h41_payload)
          xml_string  = yield encode_xml_and_schema_validate(h41_request)
          h41_xml     = yield encode_request_xml(xml_string)

          Success(h41_xml)
        end

        private

        def validate(params)
          errors = []
          errors << "family required" unless params[:family]
          errors << "agreement required" unless params[:agreement]
          errors << "insurance_policy required" unless params[:insurance_policy]
          errors << "tax_household required" unless params[:tax_household]

          errors.empty? ? Success(params) : Failure(errors)
        end

        def build_1095a_payload(values)
          tax_household = values[:tax_household]
          insurance_policy = values[:insurance_policy]
          agreement = values[:agreement]

          recipient = fetch_recipient(tax_household, agreement, values[:family])
          recipient_spouse = fetch_recipient_spouse(tax_household)
          has_aptc = tax_household.months_of_year.any? do |month|
            month.coverage_information && convert_to_currency(month.coverage_information.tax_credit).to_f > 0
          end

          provider = agreement.insurance_provider
          form_1095a_upstream_detail = {
            RecordSequenceNum: insurance_policy.policy_id,
            TaxYr: agreement.plan_year.to_s,
            CorrectedInd: "0",
            VoidInd: "0",
            MarketplaceId: "02.ME*.SBE.001.001",
            Policy: construct_policy(insurance_policy, provider),
            Recipient: construct_recipient(recipient)
          }
          form_1095a_upstream_detail.merge!(RecipientSpouse: construct_recipient_spouse(recipient_spouse)) if has_aptc && recipient_spouse.present?
          form_1095a_upstream_detail.merge!(CoverageHouseholdGrp: construct_coverage_group(tax_household))
          form_1095a_upstream_detail.merge!(RecipientPolicyInformation: construct_premium_information(tax_household))

          Success(form_1095a_upstream_detail)
        end

        def construct_premium_information(tax_household)
          {
            JanPremiumInformation: premium_information(tax_household, 1),
            FebPremiumInformation: premium_information(tax_household, 2),
            MarPremiumInformation: premium_information(tax_household, 3),
            AprPremiumInformation: premium_information(tax_household, 4),
            MayPremiumInformation: premium_information(tax_household, 5),
            JunPremiumInformation: premium_information(tax_household, 6),
            JulPremiumInformation: premium_information(tax_household, 7),
            AugPremiumInformation: premium_information(tax_household, 8),
            SepPremiumInformation: premium_information(tax_household, 9),
            OctPremiumInformation: premium_information(tax_household, 10),
            NovPremiumInformation: premium_information(tax_household, 11),
            DecPremiumInformation: premium_information(tax_household, 12),
            AnnualPolicyTotalAmounts: construct_annual_premium_totals(tax_household)
          }
        end

        def construct_annual_premium_totals(tax_household)
          annual_premiums = tax_household.annual_premiums
          annual_aptc_amount = convert_to_currency(annual_premiums.tax_credit)
          slcsp = convert_to_currency(annual_premiums.slcsp_benchmark_premium)
          {
            AnnualPremiumAmt: convert_to_currency(annual_premiums.total_premium),
            AnnualPremiumSLCSPAmt: annual_aptc_amount.present? && annual_aptc_amount.to_f > 0 ? slcsp : 0.00,
            AnnualAdvancedPTCAmt: annual_aptc_amount.present? && annual_aptc_amount.to_f > 0 ? annual_aptc_amount : 0.00
          }
        end

        def premium_information(tax_household, month)
          month = Date::MONTHNAMES[month]
          monthly_premium = tax_household.months_of_year.detect { |month_of_year| month_of_year.month == month }
          if monthly_premium
            coverage_information = monthly_premium.coverage_information
            aptc_amount = convert_to_currency(coverage_information.tax_credit)
            {
              MonthlyPremiumAmt: convert_to_currency(coverage_information.total_premium),
              MonthlyPremiumSLCSPAmt: aptc_amount.to_f > 0 ? convert_to_currency(coverage_information.slcsp_benchmark_premium) : 0.00,
              MonthlyAdvancedPTCAmt: aptc_amount.to_f > 0 ? aptc_amount : 0.00
            }
          else
            {
              MonthlyPremiumAmt: 0.00,
              MonthlyPremiumSLCSPAmt: 0.00,
              MonthlyAdvancedPTCAmt: 0.00
            }
          end
        end

        def construct_coverage_group(tax_household)
          covered_individuals = tax_household.covered_individuals
          {
            CoveredIndividuals: construct_covered_individuals(covered_individuals)
          }
        end

        def construct_covered_individuals(covered_individuals)
          covered_individuals.collect do |individual|
            {
              InsuredPerson: { OtherCompletePersonName: { PersonFirstNm: individual.person.person_name.first_name.gsub(/[^A-Za-z]/, ''),
                                                          PersonLastNm: individual.person.person_name.last_name.gsub(/[^A-Za-z]/, '') },
                               SSN: decrypt_ssn(individual.person.person_demographics&.encrypted_ssn),
                               BirthDt: individual.person.person_demographics.dob },
              CoverageStartDt: individual.coverage_start_on,
              CoverageEndDt: individual.coverage_end_on
            }
          end
        end

        def construct_recipient(recipient)
          {
            OtherCompletePersonName: { PersonFirstNm: recipient.person.person_name.first_name.gsub(/[^A-Za-z]/, ''),
                                       PersonLastNm: recipient.person.person_name.last_name.gsub(/[^A-Za-z]/, '') },
            SSN: decrypt_ssn(recipient.person.person_demographics.encrypted_ssn),
            BirthDt: recipient.person.person_demographics.dob,
            UsAddressGroup: construct_address(recipient)
          }
        end

        def construct_recipient_spouse(recipient_spouse)
          {
            OtherCompletePersonName: { PersonFirstNm: recipient_spouse.person.person_name.first_name.gsub(/[^A-Za-z]/, ''),
                                       PersonLastNm: recipient_spouse.person.person_name.last_name.gsub(/[^A-Za-z]/, '') },
            SSN: decrypt_ssn(recipient_spouse.person.person_demographics.encrypted_ssn),
            BirthDt: recipient_spouse.person.person_demographics.dob
          }
        end

        def construct_address(recipient)
          address = fetch_address(recipient)

          result = {
            AddressLine1Txt: address.address_1&.gsub(/[^0-9a-z ]/i, ''),
            CityNm: address.city&.gsub(/[^0-9a-z ]/i, ''),
            USStateCd: address.state&.gsub(/[^0-9a-z ]/i, ''),
            USZIPCd: address.zip&.gsub(/[^0-9a-z ]/i, '')
          }

          result.merge!({ AddressLine2Txt: address.address_2.gsub(/[^0-9a-z ]/i, '')  }) if address.address_2.present?

          result
        end

        def fetch_address(recipient)
          if recipient.person
            recipient.person.addresses.detect { |address| address.kind == 'mailing' } || recipient.person.addresses.first
          else
            recipient.addresses.detect { |address| address.kind == 'mailing' } || recipient.addresses.first
          end
        end

        def construct_policy(policy, provider)
          {
            MarketPlacePolicyNum: policy.policy_id,
            PolicyIssuerNm: provider.title,
            PolicyStartDt: policy.start_on,
            PolicyTerminationDt: policy.end_on
          }
        end

        def fetch_recipient(tax_household, agreement, family)
          tax_filers = tax_household.covered_individuals.select { |covered_individual| covered_individual.filer_status == 'tax_filer' }
          tax_filer =
            if tax_filers.count == 1
              tax_filers[0]
            elsif tax_filers.count > 1
              tax_filers.detect { |tx_filer| tx_filer.relation_with_primary == 'self' }
            end

          return tax_filer if tax_filer.present?

          family.family_members.detect do |family_member|
            family_member.person.hbx_id == agreement.contract_holder.hbx_id
          end
        end

        def fetch_recipient_spouse(tax_household)
          tax_household.covered_individuals.detect do |covered_individual|
            covered_individual.relation_with_primary == 'spouse'
          end
        end

        def decrypt_ssn(encrypted_ssn)
          return if encrypted_ssn.blank?

          AcaEntities::Operations::Encryption::Decrypt.new.call({ value: encrypted_ssn }).value!.gsub("-", "")
        end

        def validate_payload(payload)
          result = AcaEntities::Fdsh::H41::Contracts::Form1095aUpstreamDetailContract.new.call(payload)
          result.success? ? Success(result) : Failure("Invalid H41 request due to #{result.errors.to_h}")
        end

        def h41_request_entity(payload)
          Success(AcaEntities::Fdsh::H41::Form1095aUpstreamDetail.new(payload.to_h))
        end

        def encode_xml_and_schema_validate(payload)
          xml_string = ::AcaEntities::Serializers::Xml::Fdsh::H41::Form1095ATransmissionUpstream.domain_to_mapper(payload).to_xml
          validation = AcaEntities::Serializers::Xml::Fdsh::H41::Operations::ValidateH41RequestPayloadXml.new.call(xml_string)

          validation.success? ? Success(xml_string) : Failure("Invalid H41 xml due to #{validation.failure}")
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

        def convert_to_currency(amount)
          format('%.2f', (amount.cents / 100))
        end
      end
    end
  end
end