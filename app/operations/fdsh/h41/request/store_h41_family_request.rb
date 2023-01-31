# frozen_string_literal: true

module Fdsh
  module H41
    module Request
      # This class takes application hash as input and returns ::AcaEntities::Families::Family entity.
      class StoreH41FamilyRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @option params [Hash] :CV3_family
        # @return [Dry::Monads::Result] AcaEntities::Families::Family
        def call(params)
          values               = yield validate(params)
          family_hash          = yield validate_family(values)
          family               = yield initialize_family_entity(family_hash)
          result               = yield persist(family)

          Success(result)
        end

        private

        def validate(params)
          return Failure('cv3 family is missing') unless params[:family_hash]
          Success(params)
        end

        def validate_family(values)
          result = AcaEntities::Contracts::Families::FamilyContract.new.call(values[:family_hash])
          result.success? ? Success(result.to_h) : Failure(result)
        end

        def initialize_family_entity(family_hash)
          result = Try do
            AcaEntities::Families::Family.new(family_hash)
          end

          result.or do |e|
            Failure(e)
          end
        end

        def persist(family)
          family.households.each do |household|
            household.insurance_agreements.each do |agreement|
              agreement.insurance_policies.each do |insurance_policy|
                store_insurance_policy(insurance_policy, agreement, family)
              end
            end
          end

          Success(true)
        end

        def store_insurance_policy(insurance_policy, agreement, family)
          return if insurance_policy.aptc_csr_tax_households.blank?

          activity_hash = {
            correlation_id: "fdsh_h41_#{insurance_policy.policy_id}",
            command: "Fdsh::H41::BuildH41RequestXml",
            event_key: "h41_payload_requested",
            tax_year: insurance_policy.start_on.year.to_s
          }

          aptc_csr_tax_households = insurance_policy.aptc_csr_tax_households.collect do |aptc_csr_tax_household|
            xml_string = BuildH41Xml.new.call({
              family: family,
              insurance_policy: insurance_policy,
              agreement: agreement,
              tax_household: aptc_csr_tax_household
              }).success

            {
              hbx_assigned_id: aptc_csr_tax_household&.hbx_assigned_id,
              h41_transmission: xml_string
            }
          end

          primary_hbx_id = family.family_members.detect(&:is_primary_applicant)&.person.hbx_id

          h41_transaction_hash = {
              correlation_id: activity_hash[:correlation_id],
              activities: [activity_hash],
              cv3_family: family.to_json,
              family_hbx_id: family.hbx_id,
              primary_hbx_id: primary_hbx_id,
              policy_hbx_id: insurance_policy.policy_id,
              aptc_csr_tax_households: aptc_csr_tax_households
          }

          Try do
            Journal::H41Transactions::FindOrCreate.new.call(h41_transaction_hash)
          end
        end
      end
    end
  end
end
