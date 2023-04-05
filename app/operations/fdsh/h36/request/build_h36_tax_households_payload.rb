# frozen_string_literal: true

module Fdsh
  module H36
    module Request
      # BuildH36TaxHouseholdsPayload
      # rubocop:disable Metrics/ClassLength
      class BuildH36TaxHouseholdsPayload
        include Dry::Monads[:result, :do, :try]

        def call(params)
          valid_params = yield validate(params)
          result = yield build_tax_households(valid_params)

          Success(result)
        end

        private

        def validate(params)
          errors = []
          errors << "Please pass in family_entity" if params[:family].blank?
          errors << "Please pass in other_relevant_adult" if params[:other_relevant_adult].blank?
          errors << "Please pass in policies" if params[:insurance_policies].blank?
          errors << "Please pass in max_month" if params[:max_month].blank?

          errors.empty? ? Success(params) : Failure(errors)
        end

        def build_tax_households(valid_params)
          @max_month = valid_params[:max_month]
          @other_relevant_adult = valid_params[:other_relevant_adult]
          @family = valid_params[:family]
          insurance_policies = valid_params[:insurance_policies]
          result = insurance_policies.collect do |policy|
            next if policy.aptc_csr_tax_households.blank?

            policy.aptc_csr_tax_households.collect do |tax_household|
              {
                TaxHouseholdCoverages: construct_tax_household_coverage(tax_household, policy).flatten.compact
              }
            end
          end.flatten

          Success(result)
        end

        def construct_tax_household_coverage(tax_household, policy)
          (1..@max_month).collect do |calendar_month|
            aptc_amount = aptc_applied_for_month([tax_household], calendar_month)
            has_coverage = effectuated_for_month?([tax_household], calendar_month)
            next unless has_coverage

            result = {
              ApplicableCoverageMonthNum: prepend_zeros(calendar_month.to_s, 2)
            }
            result.merge!(Household: construct_household(tax_household, policy, calendar_month)) if aptc_amount.to_f.positive?
            result.merge!(OtherRelevantAdult: construct_other_relevant_adult) unless aptc_amount.to_f.positive?
            result
          end
        end

        def construct_household(tax_household, policy, calendar_month)
          primary = primary(tax_household)
          spouse = spouse(tax_household, primary)
          dependents = dependents(tax_household, primary)

          result = {
            PrimaryGroup: construct_tax_individual_for_primary(tax_household)
          }

          result.merge!(SpouseGroup: construct_tax_individual_for_spouse(spouse)) if spouse.present?
          result.merge!(DependentGroups: construct_tax_individual_for_dependents(dependents)) if dependents.present?
          result.merge!(AssociatedPolicies: [construct_policy(policy, tax_household, calendar_month)])
        end

        def construct_other_relevant_adult
          recipient = @other_relevant_adult
          {
            CompletePersonName: { PersonFirstName: sanitize_name(recipient.person.person_name.first_name),
                                  PersonLastName: sanitize_name(recipient.person.person_name.last_name) },
            SSN: decrypt_ssn(recipient.person.person_demographics.encrypted_ssn),
            BirthDt: recipient.person.person_demographics.dob,
            PersonAddressGroup: { UsAddressGroup: construct_address(recipient) }
          }
        end

        def construct_tax_individual_for_primary(tax_household)
          primary_thh_member = primary(tax_household)
          primary_member = fetch_primary_family_member(primary_thh_member)
          return {} if primary_member.blank?

          {
            Primary: {
              CompletePersonName: {
                PersonFirstName: sanitize_name(primary_member.person.person_name.first_name),
                PersonLastName: sanitize_name(primary_member.person.person_name.last_name)
              },
              SSN: decrypt_ssn(primary_member.person.person_demographics.encrypted_ssn),
              BirthDt: primary_member.person.person_demographics.dob,
              PersonAddressGroup: { UsAddressGroup: construct_address(primary_member) }
            }
          }
        end

        def construct_tax_individual_for_spouse(spouse)
          return if spouse.blank?

          family_member_reference = spouse.family_member_reference
          {
            Spouse: {
              CompletePersonName: {
                PersonFirstName: sanitize_name(family_member_reference.first_name),
                PersonLastName: sanitize_name(family_member_reference.last_name)
              },
              SSN: decrypt_ssn(family_member_reference.encrypted_ssn),
              BirthDt: family_member_reference.dob
            }
          }
        end

        def construct_tax_individual_for_dependents(dependents)
          return if dependents.blank?

          dependents.collect do |dependent|
            family_member_reference = dependent.family_member_reference
            {
              DependentPerson: {
                CompletePersonName: {
                  PersonFirstName: sanitize_name(family_member_reference.first_name),
                  PersonLastName: sanitize_name(family_member_reference.last_name)
                },
                SSN: decrypt_ssn(family_member_reference.encrypted_ssn),
                BirthDt: family_member_reference.dob
              }
            }
          end
        end

        def construct_policy(policy, tax_household, calendar_month)
          aptc_amount = format('%.2f', aptc_applied_for_month([tax_household], calendar_month))
          total_premium =  format('%.2f', total_premium_for_month([tax_household], calendar_month))
          slcsp_premium =  format('%.2f', slcsp_premium_for_month([tax_household], calendar_month))
          {
            QHPPolicyNum: policy.policy_id,
            QHPIssuerEIN: policy.insurance_provider.fein,
            SLCSPAdjMonthlyPremiumAmt: slcsp_premium,
            HouseholdAPTCAmt: aptc_amount,
            TotalHsldMonthlyPremiumAmt: total_premium
          }
        end

        def construct_address(recipient)
          address = fetch_address(recipient)

          result = {
            AddressLine1Txt: sanitize_address(address.address_1),
            CityNm: address.city&.gsub(/[^0-9a-z ]/i, ''),
            USStateCd: address.state&.gsub(/[^0-9a-z ]/i, ''),
            USZIPCd: sanitize_zip(address.zip)
          }

          result.merge!({ AddressLine2Txt: sanitize_address(address.address_2) }) if address.address_2.present?

          result
        end

        def sanitize_name(name)
          name.gsub(/\s+/, " ").truncate(20, :omission => '').strip
        end

        def sanitize_zip(zip)
          case zip
          when /(\d{5})-(\d{4})/
            zip.match(/(\d{5})-(\d{4})/)[1]
          when /(\d{5}).+/
            zip.match(/(\d{5}).+/)[1]
          else
            zip
          end
        end

        def sanitize_address(address)
          address.gsub(/\s+/, " ")&.truncate(35, :omission => '')&.strip
        end

        def fetch_address(recipient)
          if recipient.person
            recipient.person.addresses.detect { |address| address.kind == 'mailing' } || recipient.person.addresses.first
          else
            recipient.addresses.detect { |address| address.kind == 'mailing' } || recipient.addresses.first
          end
        end

        def fetch_primary_family_member(primary_thh_member)
          @family.family_members.detect do |family_member|
            family_member.person.hbx_id == primary_thh_member.family_member_reference.family_member_hbx_id
          end
        end

        def primary(tax_household)
          tax_household.tax_household_members.detect do |thh_member|
            thh_member.tax_filer_status == "tax_filer" ||
              thh_member.family_member_reference.relation_with_primary == "self"
          end
        end

        def spouse(tax_household, primary)
          tax_household.tax_household_members.detect do |thh_member|
            next if thh_member.family_member_reference.family_member_hbx_id == primary.family_member_reference.family_member_hbx_id

            thh_member.family_member_reference.relation_with_primary == "spouse"
          end
        end

        def dependents(tax_household, primary)
          tax_household.tax_household_members.select do |thh_member|
            next if thh_member.family_member_reference.family_member_hbx_id == primary.family_member_reference.family_member_hbx_id

            !%w[spouse self].include?(thh_member.family_member_reference.relation_with_primary)
          end
        end

        def aptc_applied_for_month(tax_households, calendar_month)
          month = Date::MONTHNAMES[calendar_month]
          calendar_month_coverages = tax_households.collect do |tax_household|
            tax_household.months_of_year.detect { |month_of_year| month_of_year.month == month }
          end

          return false if calendar_month_coverages.empty?

          calendar_month_coverages.flatten.compact.sum do |coverage|
            coverage.coverage_information && convert_to_currency(coverage.coverage_information.tax_credit).to_f
          end
        end

        def total_premium_for_month(tax_households, calendar_month)
          month = Date::MONTHNAMES[calendar_month]

          calendar_month_coverages = tax_households.collect do |tax_household|
            tax_household.months_of_year.detect { |month_of_year| month_of_year.month == month }
          end

          return false if calendar_month_coverages.empty?

          calendar_month_coverages.flatten.compact.sum do |coverage|
            coverage.coverage_information && convert_to_currency(coverage.coverage_information.total_premium).to_f
          end
        end

        def slcsp_premium_for_month(tax_households, calendar_month)
          month = Date::MONTHNAMES[calendar_month]

          calendar_month_coverages = tax_households.collect do |tax_household|
            tax_household.months_of_year.detect { |month_of_year| month_of_year.month == month }
          end

          return false if calendar_month_coverages.empty?

          calendar_month_coverages.flatten.compact.sum do |coverage|
            coverage.coverage_information && convert_to_currency(coverage.coverage_information.slcsp_benchmark_premium).to_f
          end
        end

        def effectuated_for_month?(tax_households, calendar_month)
          month = Date::MONTHNAMES[calendar_month]
          calendar_month_coverages = tax_households.collect do |tax_household|
            tax_household.months_of_year.detect { |month_of_year| month_of_year.month == month }
          end

          !calendar_month_coverages.empty?
        end

        def prepend_zeros(number, value)
          (value - number.size).times { number.prepend('0') }
          number
        end

        def convert_to_currency(amount)
          format('%.2f', (amount.cents / 100))
        end

        def decrypt_ssn(encrypted_ssn)
          return if encrypted_ssn.blank?

          AcaEntities::Operations::Encryption::Decrypt.new.call({ value: encrypted_ssn }).value!.gsub("-", "")
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
