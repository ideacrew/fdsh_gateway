# frozen_string_literal: true

module Fdsh
  module H41
    module InsurancePolicies
      # Adds a Family and Insurance Policies to the database for H41 transmission to CMS
      class Enqueue
        include Dry::Monads[:result, :do]

        # @param [Hash] opts the parameters to create the enqueued H41 notification transaction
        # @option opts [String] :correlation_id The event's unique identifier
        # @option opts [String] :family The Family and affected insurance policies serialized in Canonical Vocubulary (CV) format
        # @option opts [String] :from ('nobody') From address
        def call(params)
          values                  = yield validate(params)
          family                  = yield initialize_family_entity(values)
          policies                = yield parse_family(family)
          @corrected_transmission = yield find_or_create_transmission(:corrected)
          @original_transmission  = yield find_or_create_transmission(:original)
          @void_transmission      = yield find_or_create_transmission(:void)
          posted_family           = yield persist_family(family, policies, params[:correlation_id])

          Success("Successfully enqueued family with hbx_id: #{posted_family.family_hbx_id}, contract_holder_id: #{posted_family.contract_holder_id}")
        end

        protected

        # TODO: check with Dan and get the below code verified
        # def construct_metadata(policy, aptc_csr_thh, previous_transactions)
        #   original_transaction = previous_transactions.transmitted.detect(&:original?)
        #   return {} if original_transaction.blank?

        #   # TODO: Update below code and check with Dan.
        #   # Where do we get the original_transaction_path
        #   {
        #     original_transaction_path: {
        #       transmission_id: original_transaction.transmission.id, section_id: 2, transaction_id: original_transaction
        #     }
        #   }
        # end

        def find_transactions(aptc_csr_thh)
          ::Transmittable::Transaction.where(
            :subject_id.in => ::H41::InsurancePolicies::AptcCsrTaxHousehold.by_hbx_assigned_id(aptc_csr_thh.hbx_assigned_id).pluck(:id)
          )
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

        # Value:
        #   :transmit We always set transmit_action to 'transmit'
        #   :blocked We will set transmit_action to 'blocked' when we get event 'enroll.h41_10955as.transmission_requested' and
        #     if the policy is listed in the denied_list
        #   :no_transmit We will set transmit_action to 'no_transmit' if we do not want to transmit this transaction.
        #     Eg: We have 2 transactions for the subject and we got a new transaction, then we will only report the latest transaction.
        #         And we will update the untransmitted transactions to :no_transmit
        def find_transmit_action(previous_transactions)
          # Update all the previous transmit_pending trasactions to no_transmit. Command
          previous_transactions.transmit_pending.update_all(transmit_action: :no_transmit, status: :superseded)

          :transmit
        end

        # Check to see if there are any transactions for this policy_aptc_csr_thh combo
        # Check to see if Incoming transaction transmitted an original, if yes we check policy status to determine if it is corrected or void
        def find_type(policy, _aptc_csr_thh, previous_transactions)
          if policy.aasm_state == 'canceled'
            :void
          # No transmitted original
          elsif previous_transactions.blank? || previous_transactions.none? { |transaction| transaction.status == :transmitted }
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

          {
            transmit_action: find_transmit_action(previous_transactions),
            status: :created,
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
          Success(
            family.households.first.insurance_agreements.inject([]) do |policies, insurance_agreement|
              insurance_agreement.insurance_policies.each do |policy|
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
          posted_family = ::H41::InsurancePolicies::PostedFamily.new(
            correlation_id: correlation_id, family_cv: family.to_h.to_s, family_hbx_id: family.hbx_id,
            contract_holder_id: family.family_members.detect(&:is_primary_applicant).person.hbx_id
          )
          policies.each do |policy_hash|
            policy = posted_family.insurance_policies.build(
              assistance_year: policy_hash[:assistance_year],
              policy_hbx_id: policy_hash[:policy_hbx_id]
            )
            policy_hash[:aptc_csr_tax_households].each do |aptc_csr_thh_hash|
              aptc_csr_tax_household = policy.aptc_csr_tax_households.build(
                hbx_assigned_id: aptc_csr_thh_hash[:hbx_assigned_id], transaction_xml: aptc_csr_thh_hash[:transaction_xml]
              )
              transaction = aptc_csr_tax_household.transactions.build(
                transmission: find_transmission(aptc_csr_thh_hash[:transaction][:type]),
                transmit_action: aptc_csr_thh_hash[:transaction][:transmit_action],
                status: aptc_csr_thh_hash[:transaction][:status], type: aptc_csr_thh_hash[:transaction][:type],
                started_at: aptc_csr_thh_hash[:transaction][:started_at]
              )
              transaction

              # TODO: Create H41::Transmissions::TransmissionPath
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
