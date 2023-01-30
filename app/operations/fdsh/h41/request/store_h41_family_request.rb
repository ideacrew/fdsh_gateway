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
          family = yield initialize_family_entity(family_hash)
          _updated_transaction = yield store_request(family)

          Success(application)
        end

        private

        def validate(params)
          return Failure('cv3 family is missing') unless params[:family_hash]
          Success(params)
        end

        def validate_family(values)
          result = AcaEntities::Contracts::Families::FamilyContract.new.call(values[:family_hash])
          result.success? ? result.to_h : Failure(result)
        end

        def initialize_family_entity(family_hash)
          result = Try do
            AcaEntities::Families::Family.new(family_hash)
          end

          result.or do |e|
            Failure(e)
          end
        end

        def store_request(family)
          family.households.each do |household|
            household.insurance_agreements.each do |agreement|
              agreement.insurance_policies.each do |insurance_policy|
                next if insurance_policy.aptc_csr_tax_households.blank?

                create_or_update_transaction("request", family, insurance_policy)
              end
            end
          end

          Success(true)
        end

        def create_or_update_transaction(key, family, insurance_policy)
          activity_hash = {
            correlation_id: "fdsh_h41_#{insurance_policy.policy_id}",
            command: "Fdsh::H41::BuildH41RequestXml",
            event_key: "h41_payload_requested",
            message: { "#{key}": family.to_json },
            tax_year: insurance_policy.start_on.year
          }

          family_irs_group_id = family.hbx_id
          primary_hbx_id = family.family_members.detect(&:is_primary_applicant)&.person_hbx_id
          transaction_hash = {
            correlation_id: activity_hash[:correlation_id],
            activity: activity_hash,
            family: family.to_json,
            family_hbx_id: family_irs_group_id,
            primary_hbx_id: primary_hbx_id
          }
          Try do
            Journal::Transactions::AddActivity.new.call(transaction_hash)
          end
        end
      end
    end
  end
end
