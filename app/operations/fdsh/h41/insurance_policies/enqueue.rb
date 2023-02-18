# frozen_string_literal: true

module Fdsh
  module H41
    module InsurancePolicies
      # Adds a Family, Insurance Policies, Aptc Csr TaxHousheolds, Transactions and Transmissions to the database for H41 transmission to CMS
      # This operation does all the below:
      #   1. creates database model Posted Family
      #   2. creates database model Insurance Policies
      #   3. creates database model Aptc Csr TaxHousheolds(Subject)
      #   4. creates database model Transactions
      #   5. FindOrCreate H41 Transmissions(Corrected, Original, and Void)
      #   6. creates database model Transmittable::TransactionsTransmissions, the join table between Transactions and H41 Transmissions
      #   7. Updates all the :untransmitted transactions that map to the subject
      class Enqueue
        include Dry::Monads[:result, :do]

        # @param [Hash] opts the parameters to create the enqueued H41 notification transaction
        # @option opts [String] :correlation_id The event's unique identifier
        # @option opts [String] :family The Family and affected insurance policies serialized in Canonical Vocubulary (CV) format
        # @option opts [String] :from ('nobody') From address
        def call(params)
          values                  = yield validate(params)
          family_cv               = yield validate_family_cv(values)
          family                  = yield initialize_family_entity(family_cv)
          policies                = yield parse_family(family, values)
          @corrected_transmission = yield find_or_create_transmission(:corrected)
          @original_transmission  = yield find_or_create_transmission(:original)
          @void_transmission      = yield find_or_create_transmission(:void)
          posted_family           = yield persist_family(family, policies, params[:correlation_id])

          Success("Successfully enqueued family with hbx_id: #{posted_family.family_hbx_id}, contract_holder_id: #{posted_family.contract_holder_id}")
        end

        protected

        def create_posted_family(correlation_id, family)
          ::H41::InsurancePolicies::PostedFamily.create(
            contract_holder_id: family.family_members.detect(&:is_primary_applicant).person.hbx_id,
            correlation_id: correlation_id,
            family_cv: family.to_h.to_json,
            family_hbx_id: family.hbx_id
          )
        end

        def create_transactions_transmissions(transmission, transaction)
          Transmittable::TransactionsTransmissions.create(
            transmission: transmission,
            transaction: transaction
          )
        end

        def fetch_affected_policies(insurance_policies, affected_policy_hbx_ids)
          insurance_policies.select { |policy| affected_policy_hbx_ids.include?(policy.policy_id)  }
        end

        def find_transactions(aptc_csr_thh)
          subjects = ::H41::InsurancePolicies::AptcCsrTaxHousehold.by_hbx_assigned_id(aptc_csr_thh.hbx_assigned_id)
          ::Transmittable::Transaction.where(:transactable_id.in => subjects.pluck(:id))
        end

        def find_transmission(transaction_type)
          case transaction_type
          when :corrected
            @corrected_transmission
          when :original
            @original_transmission
          when :void
            @void_transmission
          else
            ''
          end
        end

        def find_transmission_type(policy, previous_transactions)
          if policy.aasm_state == 'canceled'
            :void
          elsif previous_transactions.blank? || previous_transactions.transmitted.none?
            :original
          else
            :corrected
          end
        end

        def find_or_create_transmission(transmission_type)
          ::Fdsh::H41::Transmissions::Open::FindOrCreate.new.call({ transmission_type: transmission_type })
        end

        def initialize_family_entity(payload)
          Success(::AcaEntities::Families::Family.new(payload))
        end

        def parse_aptc_csr_tax_households(family, insurance_agreement, policy)
          policy.aptc_csr_tax_households.inject([]) do |thhs_array, aptc_csr_thh|
            thhs_array << {
              hbx_assigned_id: aptc_csr_thh.hbx_assigned_id,
              transaction_xml: Fdsh::H41::Request::BuildH41Xml.new.call(
                {
                  agreement: insurance_agreement,
                  family: family,
                  insurance_policy: policy,
                  tax_household: aptc_csr_thh
                }
              ).success,
              transaction: parse_transaction(policy, aptc_csr_thh)
            }
            thhs_array
          end
        end

        def parse_transaction(policy, aptc_csr_thh)
          previous_transactions = find_transactions(aptc_csr_thh)
          update_previous_transactions(previous_transactions)
          transmission_type = find_transmission_type(policy, previous_transactions)

          # If current transaction is void and we never transmitted this subject before, then status is :superseded, transmit_action is :no_transmit
          if transmission_type == :void && previous_transactions.transmitted.none?
            { transmit_action: :no_transmit, status: :superseded, transmission_type: transmission_type, started_at: Time.now }
          else
            { transmit_action: :transmit, status: :created, transmission_type: transmission_type, started_at: Time.now }
          end
        end

        # Extract information that matches with the persistence models.
        def parse_family(family, values)
          Success(
            family.households.first.insurance_agreements.inject([]) do |policies, insurance_agreement|
              insurance_policies = fetch_affected_policies(insurance_agreement.insurance_policies, values[:affected_policies])
              insurance_policies.each do |policy|
                policies << {
                  policy_hbx_id: policy.policy_id,
                  assistance_year: insurance_agreement.plan_year,
                  aptc_csr_tax_households: parse_aptc_csr_tax_households(family, insurance_agreement, policy)
                }
              end
              policies
            end
          )
        end

        def persist_family(family, policies, correlation_id)
          posted_family = create_posted_family(correlation_id, family)

          policies.each do |policy_hash|
            policy = posted_family.insurance_policies.create(
              assistance_year: policy_hash[:assistance_year],
              policy_hbx_id: policy_hash[:policy_hbx_id]
            )
            policy_hash[:aptc_csr_tax_households].each do |aptc_csr_thh_hash|
              aptc_csr_tax_household = policy.aptc_csr_tax_households.create(
                hbx_assigned_id: aptc_csr_thh_hash[:hbx_assigned_id], transaction_xml: aptc_csr_thh_hash[:transaction_xml]
              )
              transaction = aptc_csr_tax_household.transactions.create(
                transmit_action: aptc_csr_thh_hash[:transaction][:transmit_action],
                status: aptc_csr_thh_hash[:transaction][:status],
                started_at: aptc_csr_thh_hash[:transaction][:started_at]
              )

              create_transactions_transmissions(
                find_transmission(aptc_csr_thh_hash[:transaction][:transmission_type]),
                transaction
              )
            end
          end

          Success(posted_family)
        end

        def update_previous_transactions(previous_transactions)
          previous_transactions.transmit_pending.update_all(status: :superseded, transmit_action: :no_transmit)
        end

        def validate(params)
          if params[:affected_policies].is_a?(Array) && params[:correlation_id].is_a?(String) && params[:family].present?
            Success(params)
          else
            Failure('Invalid params. affected_policies, correlation_id and family are required.')
          end
        end

        # Validates params using AcaEntities Family contract
        def validate_family_cv(values)
          result = AcaEntities::Contracts::Families::FamilyContract.new.call(values[:family])

          if result.success?
            Success(result.to_h)
          else
            Failure(result.errors.to_h)
          end
        end
      end
    end
  end
end
