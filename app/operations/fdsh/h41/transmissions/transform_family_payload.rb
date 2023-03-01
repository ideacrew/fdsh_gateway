# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      # Operation to publish an open transmission of given kind
      class TransformFamilyPayload
        include Dry::Monads[:result, :do, :try]

        H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

        def call(params)
          values                = yield validate(params)
          insurance_policies    = yield fetch_insurance_policies(values[:insurance_policy_ids])
          posted_family         = yield fetch_posted_family(insurance_policies)
          family_hash           = yield validate_family_json_hash(posted_family)
          transformed_payload   = yield transform_family_payload(family_hash, values, insurance_policies)

          Success(transformed_payload)
        end

        private

        def validate(params)
          return Failure('family_hbx_id required') unless params[:family_hbx_id]
          return Failure('reporting year required') unless params[:reporting_year]
          return Failure('report_type required ') unless params[:report_type]
          return Failure('insurance_policy_ids required ') unless params[:insurance_policy_ids]
          unless params[:report_type] && H41_TRANSMISSION_TYPES.include?(params[:report_type])
            return Failure("report_type must be one #{H41_TRANSMISSION_TYPES.map(&:to_s).join(', ')}")
          end

          Success(params)
        end

        def fetch_insurance_policies(insurance_policy_ids)
          Success(::H41::InsurancePolicies::InsurancePolicy.in(id: insurance_policy_ids))
        end

        def fetch_posted_family(insurance_policies)
          Success(insurance_policies.order(:created_at.desc).first.posted_family)
        end

        def validate_family_json_hash(posted_family)
          family_hash = JSON.parse(posted_family.family_cv, symbolize_names: true)
          validation_result = AcaEntities::Contracts::Families::FamilyContract.new.call(family_hash)
          validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
        end

        def transform_family_payload(family_hash, values, insurance_policies)
          policy_hbx_ids = insurance_policies.pluck(:policy_hbx_id)
          insurance_agreements = family_hash[:households][0][:insurance_agreements]
          family_hash[:households][0][:insurance_agreements] = fetch_insurance_agreements(insurance_agreements, values)
          family_hash[:households][0][:insurance_agreements].each do |agreement|
            agreement[:insurance_policies] = fetch_valid_policies(agreement[:insurance_policies].flatten, policy_hbx_ids)
            agreement[:insurance_policies].each do |insurance_policy|
              insurance_policy[:aptc_csr_tax_households] = insurance_policy[:aptc_csr_tax_households].collect do |tax_household|
                case values[:report_type]
                when :void
                  tax_household.merge(void: true)
                when :corrected
                  tax_household.merge(corrected: true)
                end
              end
            end.compact
          end

          Success(family_hash)
        end

        def fetch_insurance_agreements(insurance_agreements, values)
          insurance_agreements.select do |agreement|
            agreement[:plan_year].to_s == values[:reporting_year].to_s
          end
        end

        def fetch_valid_policies(insurance_policies, policy_hbx_ids)
          insurance_policies.select do |policy|
            policy_hbx_ids.include?(policy[:policy_id])
          end.flatten
        end

        def fetch_valid_tax_households(policies, values)
          policies.collect do |policy|
            fetch_affected_tax_households(policy[:aptc_csr_tax_households], values[:subject_hbx_ids])
          end.flatten
        end

        def fetch_affected_tax_households(tax_households, subject_hbx_ids)
          tax_households.select { |tax_household| subject_hbx_ids.include?(tax_household[:hbx_assigned_id]) }
        end
      end
    end
  end
end
