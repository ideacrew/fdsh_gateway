# frozen_string_literal: true

module Fdsh
  module H36
    module Request
      # BuildH36InsurancePoliciesPayload
      class BuildH36InsurancePoliciesPayload
        include Dry::Monads[:result, :do, :try]

        def call(params)
          valid_params = yield validate(params)
          result = yield build_insurance_coverages(valid_params)

          Success(result)
        end

        private

        def validate(params)
          errors = []
          errors << "Please pass in policies" if params[:insurance_policies].blank?
          errors << "Please pass in max_month" if params[:max_month].blank?

          errors.empty? ? Success(params) : Failure(errors)
        end

        def build_insurance_coverages(valid_params)
          @max_month = valid_params[:max_month]
          insurance_policies = valid_params[:insurance_policies]

          result = insurance_policies.collect do |policy|
            next if policy.aptc_csr_tax_households.blank?

            tax_households = policy.aptc_csr_tax_households
            {
              InsuranceCoverages: construct_insurance_coverage(tax_households, policy).flatten.compact
            }
          end

          Success(result)
        end

        def construct_insurance_coverage(tax_households, policy)
          (1..@max_month).collect do |calendar_month|
            has_coverage = effectuated_for_month?(tax_households, calendar_month)
            next unless has_coverage

            aptc_amount = format('%.2f', aptc_applied_for_month(tax_households, calendar_month))
            total_premium =  format('%.2f', total_premium_for_month(tax_households, calendar_month))
            slcsp_premium =  format('%.2f', slcsp_premium_for_month(tax_households, calendar_month))

            result = {
              ApplicableCoverageMonthNum: prepend_zeros(calendar_month.to_s, 2),
              QHPPolicyNum: policy.policy_id,
              QHPIssuerEIN: policy.insurance_provider.fein,
              IssuerNm: policy.insurance_provider.title,
              PolicyCoverageStartDt: policy.start_on,
              PolicyCoverageEndDt: policy.end_on,
              TotalQHPMonthlyPremiumAmt: total_premium,
              APTCPaymentAmt: aptc_amount.to_f > 0 ? slcsp_premium : 0.00,
              CoveredIndividuals: construct_covered_individuals(tax_households).compact
            }
            result.merge!(SLCSPMonthlyPremiumAmt: slcsp_premium) unless aptc_amount.to_f > 0
            result
          end
        end

        def effectuated_for_month?(tax_households, calendar_month)
          month = Date::MONTHNAMES[calendar_month]
          calendar_month_coverages = tax_households.collect do |tax_household|
            tax_household.months_of_year.detect { |month_of_year| month_of_year.month == month }
          end

          !calendar_month_coverages.empty?
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

        def construct_covered_individuals(tax_households)
          covered_individuals = tax_households.collect(&:covered_individuals)

          covered_individuals.flatten.compact.collect do |individual|
            {
              InsuredPerson: { CompletePersonName: {
                PersonFirstName: sanitize_name(individual.person.person_name.first_name),
                PersonLastName: sanitize_name(individual.person.person_name.last_name)
              },
                               SSN: decrypt_ssn(individual.person.person_demographics&.encrypted_ssn),
                               BirthDt: individual.person.person_demographics.dob },
              CoverageStartDt: individual.coverage_start_on,
              CoverageEndDt: individual.coverage_end_on
            }
          end
        end

        def convert_to_currency(amount)
          format('%.2f', (amount.cents / 100))
        end

        def decrypt_ssn(encrypted_ssn)
          return if encrypted_ssn.blank?

          AcaEntities::Operations::Encryption::Decrypt.new.call({ value: encrypted_ssn }).value!.gsub("-", "")
        end

        def prepend_zeros(number, value)
          (value - number.size).times { number.prepend('0') }
          number
        end

        def sanitize_name(name)
          name.gsub(/\s+/, " ").truncate(20, :omission => '').strip
        end
      end
    end
  end
end
