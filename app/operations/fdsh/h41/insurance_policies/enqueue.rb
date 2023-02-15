# frozen_string_literal: true

module Fdsh
  module H41
    module InsurancePolicies
      # Adds a Family and Insurance Policies to the database for H41 transmission to CMS
      class Enqueue
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param [Hash] opts the parameters to create the enqueued H41 notification transaction
        # @option opts [String] :correlation_id The event's unique identifier
        # @option opts [String] :family The Family and affected insurance policies serialized in Canonical Vocubulary (CV) format
        # @option opts [String] :from ('nobody') From address
        def call(params)
          values = yield validate(params)
          family = yield initialize_family_entity(values)
          policies = yield parse_family(family)
          _persisted_posted_family = yield persist_family(family, policies, params[:correlation_id])
          require 'pry'; binding.pry
          _result = yield enqueue(policies, family)

          Success('Successfully processed event: edi_gateway.insurance_policies.posted')
        end

        protected

        # def construct_metadata(policy, aptc_csr_thh, previous_transactions)
        #   original_transaction = previous_transactions.any? do |transaction|
        #     transaction.type == :original && transaction.status == :transmitted
        #   end.first
        #   return {} if original_transaction.blank?
        #   {
        #     original_transaction_path: {
        #       transmission_id: original_transaction.transmission.id, section_id: 2, transaction_id: original_transaction
        #     }
        #   }
        # end

        # Adds the Family event and its updated policies to the transmission list
        # Find all the policy/apct_csr_thhs transactions and verify if that is transmitted or not.
        # Update the transaction models.
        def enqueue(_policies, _family)
          Success('')
        end

        def find_all_matching_transactions(_family, _policy, aptc_csr_thh)
          ::Transmittable::Transaction.where(
            :subject_id.in => ::H41::InsurancePolicies::AptcCsrTaxHousehold.by_hbx_assigned_id(aptc_csr_thh.hbx_assigned_id).pluck(:id)
          )
        end

        # TODO: Understand what is status and fix the method
        # Value:
        #   :created default
        #   :updated We will set transmit_action to 'updated' when we get event 'enroll.h41_10955as.transmission_requested'
        def find_status(_policy, _aptc_csr_thh, _previous_transactions)
          :created
        end

        def find_transmission(transaction_type)
          case transaction_type
          when :corrected
            ::H41::CorrectedTransmission.first.communication
          when :original
            ::H41::OriginalTransmission.first.communication
          when :void
            ::H41::VoidTransmission.first.communication
          else
          end
        end

        # Value:
        #   :transmit We always set transmit_action to 'transmit'
        #   :blocked We will set transmit_action to 'blocked' when we get event 'enroll.h41_10955as.transmission_requested' and
        #     if the policy is listed in the denied_list
        #   :no_transmit We will set transmit_action to 'no_transmit' when the last transaction is voided(policy is canceled).
        #     Eg: Create, Canceled, Reinstated for same Policy
        def find_transmit_action(_policy, _aptc_csr_thh, _previous_transactions)
          :transmit
        end

        # 1. Scope to find all transmitted originals type: :original, status: :transmitted, subject_id: aptc_cst_thh.id
        # 2. Scope to find Untransmitted transactions of the policy and aptc_cst_thh subject_id: aptc_cst_thh.id, transmit_action: :transmit
        # 3. Is the inbound transaction a 'void'?

        # Check to see if there are any transactions for this policy_aptc_csr_thh combo
        # Return check to see if Incoming transaction transmitted an original, if yes we check policy status to determine if it is corrected or void

        def find_type(policy, _aptc_csr_thh, previous_transactions)
          # policy.start_on.present? && policy.end_on.present? && policy.start_on == policy.end_on
          if policy.aasm_state == 'canceled'
            :void
          elsif previous_transactions.blank? || previous_transactions.none? { |transaction| transaction.status == :transmitted }
            :original
          else
            :corrected
          end
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
              transaction: parse_transaction(family, policy, aptc_csr_thh)
            }
            thhs_array
          end
        end

        def parse_transaction(family, policy, aptc_csr_thh)
          previous_transactions = find_all_matching_transactions(family, policy, aptc_csr_thh)

          {
            transmit_action: find_transmit_action(policy, aptc_csr_thh, previous_transactions),
            status: find_status(policy, aptc_csr_thh, previous_transactions),
            type: find_type(policy, aptc_csr_thh, previous_transactions),
            # transaction_errors: [],
            # metadata: construct_metadata(policy, aptc_csr_thh, previous_transactions),
            started_at: Time.now
            # end_at: find_end_at(policy, aptc_csr_thh, previous_transactions)
          }
        end

        # Returns the updated policies and attributes from the Family payload
        # Extract information that matches with the persistence models.
        def parse_family(family)
          policies = []

          family.households.first.insurance_agreements.each do |insurance_agreement|
            insurance_agreement.insurance_policies.each do |policy|
              policies << {
                policy_hbx_id: policy.policy_id,
                assistance_year: insurance_agreement.plan_year,
                aptc_csr_tax_households: parse_aptc_csr_tax_households(family, insurance_agreement, policy)
              }
            end
          end

          Success(policies)
        end

        def persist_family(family, policies, correlation_id)
          posted_family = ::H41::InsurancePolicies::PostedFamily.new(
            correlation_id: correlation_id,
            contract_holder_id: family.family_members.detect(&:is_primary_applicant).person.hbx_id,
            family_cv: family.to_h.to_s,
            family_hbx_id: family.hbx_id
          )

          policies.each do |policy_hash|
            policy = posted_family.insurance_policies.build(
              assistance_year: policy_hash[:assistance_year],
              policy_hbx_id: policy_hash[:policy_hbx_id]
            )

            policy_hash[:aptc_csr_tax_households].each do |aptc_csr_thh_hash|
              aptc_csr_tax_household = policy.aptc_csr_tax_households.build(
                hbx_assigned_id: aptc_csr_thh_hash[:hbx_assigned_id],
                transaction_xml: aptc_csr_thh_hash[:transaction_xml]
              )

              aptc_csr_tax_household.transactions.build(
                transmission: find_transmission(aptc_csr_thh_hash[:transaction][:type]),
                transmit_action: aptc_csr_thh_hash[:transaction][:transmit_action],
                status: aptc_csr_thh_hash[:transaction][:status],
                type: aptc_csr_thh_hash[:transaction][:type],
                # metadata
                started_at: aptc_csr_thh_hash[:transaction][:started_at]
                # end_at
              )
            end
          end

          posted_family.save!

          Success(posted_family)
        end

        # Validates params using AcaEntities Family contract
        def validate(params)
          result = AcaEntities::Contracts::Families::FamilyContract.new.call(params[:family])

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
