# frozen_string_literal: true

module Fdsh
  module H36
    module IrsGroups
      # Adds a Family to the database for H36 transmission to CMS
      class Enqueue
        include Dry::Monads[:result, :do]

        # @param [Hash] opts the parameters to create the enqueued H41 notification transaction
        # @option opts [String] :correlation_id The event's unique identifier
        # @option opts [String] :family The Family and affected insurance policies serialized in Canonical Vocubulary (CV) format
        # @option opts [String] :from ('nobody') From address
        def call(params)
          values                       = yield validate(params)
          family_cv                    = yield validate_family_cv(values[:family])
          family_entity                = yield initialize_family_entity(family_cv)
          existing_irs_group           = yield find_existing_irs_group(values, family_entity)
          transmission                 = yield find_or_create_transmission(params[:assistance_year])
          _result                      = yield update_previous_transactions(existing_irs_group)
          irs_group                    = yield persist_irs_group(transmission, family_entity, values)

          Success("Successfully enqueued irs_group with hbx_id: #{irs_group.family_hbx_id},
contract_holder_hbx_id: #{irs_group.contract_holder_hbx_id}")
        end

        private

        def validate(params)
          return Failure("Please pass in family") if params[:family].blank?
          return Failure("Please pass in assistance_year") if params[:assistance_year].blank?
          return Failure("Please pass in correlation_id") if params[:correlation_id].blank?

          Success(params)
        end

        def validate_family_cv(family_hash)
          result = AcaEntities::Contracts::Families::FamilyContract.new.call(family_hash)
          result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
        end

        def initialize_family_entity(family_contract_hash)
          Success(::AcaEntities::Families::Family.new(family_contract_hash))
        end

        def find_or_create_transmission(assistance_year)
          ::Fdsh::H36::Transmissions::FindOrCreate.new.call({ assistance_year: assistance_year })
        end

        def find_existing_irs_group(values, family)
          result = Fdsh::H36::IrsGroups::Find.new.call({ family_hbx_id: family.hbx_id,
                                                         assistance_year: values[:assistance_year] })
          return Success(nil) if result.failure?

          result
        end

        def update_previous_transactions(existing_irs_group)
          return Success(true) unless existing_irs_group

          previous_transactions = existing_irs_group.transactions.transmit_pending
          previous_transactions.update_all(transmit_action: :no_transmit, status: :superseded)
          Success(true)
        end

        def persist_irs_group(transmission, family_entity, values)
          any_effectuated_coverage = any_effectuated_coverage?(family_entity)
          contract_holder_hbx_id = family_entity.family_members.detect(&:is_primary_applicant).person.hbx_id

          irs_group = ::H36::IrsGroups::IrsGroup.create!(
            correlation_id: values[:correlation_id],
            family_cv: family_entity.to_h.to_json,
            family_hbx_id: family_entity.hbx_id,
            contract_holder_hbx_id: contract_holder_hbx_id,
            assistance_year: values[:assistance_year]
          )
          transmit_action = any_effectuated_coverage ? :transmit : :no_transmit
          status = any_effectuated_coverage ? :created : :excluded
          transaction = ::Transmittable::Transaction.create!(transmit_action: transmit_action,
                                                             status: status, started_at: Time.now,
                                                             transactable: irs_group)
          create_transactions_transmissions(transmission, transaction)
          Success(irs_group)
        end

        def create_transactions_transmissions(transmission, transaction)
          Transmittable::TransactionsTransmissions.create(
            transmission: transmission,
            transaction: transaction
          )
        end

        def any_effectuated_coverage?(family_entity)
          insurance_agreements = family_entity.households.first.insurance_agreements
          insurance_policies = insurance_agreements.flat_map(&:insurance_policies)
          return false if insurance_policies.empty?

          insurance_policies.any? { |insurance_policy| insurance_policy.aasm_state != "canceled"}
        end
      end
    end
  end
end
