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
      #   5. Find H41 Transmissions(Corrected, Original, and Void) for given reporting year
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
          family                  = yield initialize_family_entity(values[:family])
          policies                = yield parse_family(family, values)
          @corrected_transmission = yield find_transmission(:corrected, params[:assistance_year])
          @original_transmission  = yield find_transmission(:original, params[:assistance_year])
          @void_transmission      = yield find_transmission(:void, params[:assistance_year])
          posted_family           = yield persist_family(family, policies, params)

          Success("Successfully enqueued family with hbx_id: #{posted_family.family_hbx_id}, contract_holder_id: #{posted_family.contract_holder_id}")
        end

        protected

        def build_transaction_xml(params)
          attrs = params[:parsed_transaction]

          # Handle BuildH41Xml for cases where a void comes in and we never transmitted original.
          # DO NOT GENERATE THE XML. set this to empty string as we cannot send record_sequence_num of the original.
          return '' if attrs[:transmit_action] == :no_transmit && attrs[:status] == :blocked && attrs[:transmission_type] == :void

          build_result = Fdsh::H41::Request::BuildH41Xml.new.call(
            {
              agreement: params[:agreement],
              family: params[:family],
              insurance_policy: params[:insurance_policy],
              tax_household: params[:tax_household],
              transaction_type: params[:transaction_type],
              record_sequence_num: find_record_sequence_num(params[:previous_transactions], params[:transaction_type])
            }
          )

          @transaction_errors_hash = { transaction_xml: error_messages(build_result) } if build_result.failure?

          build_result.success
        end

        def create_aptc_csr_tax_household(policy, aptc_csr_thh_hash)
          policy.aptc_csr_tax_households.create(
            corrected: aptc_csr_thh_hash[:corrected],
            hbx_assigned_id: aptc_csr_thh_hash[:hbx_assigned_id],
            original: aptc_csr_thh_hash[:original],
            primary_tax_filer_hbx_id: aptc_csr_thh_hash[:primary_tax_filer_hbx_id],
            transaction_xml: aptc_csr_thh_hash[:transaction_xml],
            void: aptc_csr_thh_hash[:void]
          )
        end

        def create_posted_family(correlation_id, family)
          ::H41::InsurancePolicies::PostedFamily.create(
            contract_holder_id: primary_person_hbx_id(family),
            correlation_id: correlation_id,
            family_cv: family.to_h.to_json,
            family_hbx_id: family.hbx_id
          )
        end

        def create_transaction(aptc_csr_tax_household, aptc_csr_thh_hash)
          aptc_csr_tax_household.transactions.create(
            transmit_action: fetch_transmit_action(aptc_csr_thh_hash[:transaction][:transmit_action]),
            transaction_errors: @transaction_errors_hash || {},
            status: fetch_status(aptc_csr_thh_hash[:transaction][:status]),
            started_at: aptc_csr_thh_hash[:transaction][:started_at]
          )
        end

        def create_transactions_transmissions(transmission, transaction)
          ::Transmittable::TransactionsTransmissions.create(
            transmission: transmission,
            transaction: transaction
          )
        end

        def error_messages(build_result)
          if build_result.failure.is_a?(Dry::Validation::Result)
            build_result.failure.errors.to_h
          else
            build_result.failure
          end
        end

        def eligible_policy?(policy, assistance_year)
          return false if policy.insurance_product.metal_level == 'catastrophic'
          return false if policy.carrier_policy_id.blank? && policy.aasm_state != 'canceled'
          return false if policy.insurance_product.coverage_type == 'dental'
          return false if policy.start_on.year != assistance_year

          true
        end

        def fetch_affected_policies(insurance_policies, affected_policy_hbx_ids, assistance_year)
          insurance_policies.select do |policy|
            affected_policy_hbx_ids.include?(policy.policy_id) && eligible_policy?(policy, assistance_year)
          end
        end

        def fetch_status(status)
          @transaction_errors_hash.present? ? :errored : status
        end

        def fetch_transmit_action(transmit_action)
          @transaction_errors_hash.present? ? :no_transmit : transmit_action
        end

        def find_transmission(transmission_type, reporting_year)
          ::Fdsh::H41::Transmissions::Find.new.call(
            {
              reporting_year: reporting_year,
              status: :open,
              transmission_type: transmission_type
            }
          )
        end

        def find_record_sequence_num(previous_transactions, transaction_type)
          return nil if transaction_type == :original

          original_transaction = previous_transactions.transmitted.detect do |transaction|
            transaction.transactable.original?
          end

          # Case where we never transmitted Original and the policy is canceled, then the transaction is void with transmit_action is :no_transmit
          return nil if transaction_type == :void && original_transaction.blank?

          ::H41::Transmissions::TransmissionPath.where(transaction_id: original_transaction.id).first.record_sequence_number_path
        end

        def find_transactions(policy, aptc_csr_thh)
          insurance_policies = ::H41::InsurancePolicies::InsurancePolicy.where(policy_hbx_id: policy.policy_id)

          subjects = ::H41::InsurancePolicies::AptcCsrTaxHousehold.where(
            :insurance_policy_id.in => insurance_policies.pluck(:id),
            primary_tax_filer_hbx_id: aptc_csr_thh.primary_tax_filer_hbx_id
          )

          ::Transmittable::Transaction.where(:transactable_id.in => subjects.pluck(:id)).order(created_at: :desc)
        end

        def fetch_transmission(transaction_type)
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

        def initialize_family_entity(payload)
          ::AcaEntities::Operations::CreateFamily.new.call(payload)
        end

        def parse_aptc_csr_tax_households(family, insurance_agreement, policy)
          policy.aptc_csr_tax_households.inject([]) do |thhs_array, aptc_csr_thh|
            previous_transactions = find_transactions(policy, aptc_csr_thh)
            update_previous_transmit_pending_transactions(previous_transactions)
            transmission_type = find_transmission_type(policy, previous_transactions)
            transaction_hash = parse_transaction(transmission_type, previous_transactions, aptc_csr_thh)

            thhs_array << {
              corrected: transmission_type == :corrected,
              original: transmission_type == :original,
              void: transmission_type == :void,
              hbx_assigned_id: aptc_csr_thh.hbx_assigned_id,
              primary_tax_filer_hbx_id: aptc_csr_thh.primary_tax_filer_hbx_id,
              transaction_xml: build_transaction_xml(
                {
                  agreement: insurance_agreement,
                  family: family, insurance_policy: policy,
                  parsed_transaction: transaction_hash,
                  previous_transactions: previous_transactions,
                  tax_household: aptc_csr_thh,
                  transaction_type: transmission_type
                }
              ),
              transaction: transaction_hash
            }
            thhs_array
          end
        end

        def duplicate_transaction?(previous_transactions, aptc_csr_thh)
          latest_transmitted_transaction = previous_transactions.transmitted.first
          return false if latest_transmitted_transaction.blank?

          subject = latest_transmitted_transaction.transactable
          insurance_policy = subject.insurance_policy
          previous_aptc_csr_thh = insurance_policy.posted_family.family_entity.find_policy_by(
            insurance_policy.policy_hbx_id
          ).find_tax_household_by(
            subject.primary_tax_filer_hbx_id
          )
          previous_aptc_csr_thh.tax_household_same_as?(aptc_csr_thh)
        end

        # If current transaction is void and we never transmitted this subject before, then status is :blocked, transmit_action is :no_transmit
        # If the current transaction is not different when compared against the most recently transmitted transaction,
        #   then the status is :duplicate, transmit_action is :no_transmit
        def parse_transaction(transmission_type, previous_transactions, aptc_csr_thh)
          if transmission_type == :void && previous_transactions.transmitted.none?
            { transmit_action: :no_transmit, status: :blocked, transmission_type: transmission_type, started_at: Time.now }
          elsif duplicate_transaction?(previous_transactions, aptc_csr_thh)
            { transmit_action: :no_transmit, status: :duplicate, transmission_type: transmission_type, started_at: Time.now }
          else
            { transmit_action: :transmit, status: :created, transmission_type: transmission_type, started_at: Time.now }
          end
        end

        # Extract information that matches with the persistence models.
        def parse_family(family, values)
          Success(
            family.households.first.insurance_agreements.inject([]) do |policies, insurance_agreement|
              insurance_policies = fetch_affected_policies(
                insurance_agreement.insurance_policies,
                values[:affected_policies],
                values[:assistance_year]
              )

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

        def persist_family(family, policies, params)
          assistance_year = params[:assistance_year]
          correlation_id = params[:correlation_id]

          if policies.blank?
            return Failure(
              "No valid policies to process for given family with family_hbx_id: #{
                family.hbx_id} primary_person_hbx_id: #{primary_person_hbx_id(family)} for assistance_year: #{
                  assistance_year} correlation_id: #{correlation_id}"
            )
          end

          posted_family = create_posted_family(correlation_id, family)

          policies.each do |policy_hash|
            policy = posted_family.insurance_policies.create(
              assistance_year: policy_hash[:assistance_year],
              policy_hbx_id: policy_hash[:policy_hbx_id]
            )

            policy_hash[:aptc_csr_tax_households].each do |aptc_csr_thh_hash|
              aptc_csr_tax_household = create_aptc_csr_tax_household(policy, aptc_csr_thh_hash)
              transaction = create_transaction(aptc_csr_tax_household, aptc_csr_thh_hash)

              create_transactions_transmissions(
                fetch_transmission(aptc_csr_thh_hash[:transaction][:transmission_type]),
                transaction
              )
            end
          end

          Success(posted_family)
        end

        def primary_person_hbx_id(family)
          family.family_members.detect(&:is_primary_applicant).person.hbx_id
        end

        def update_previous_transmit_pending_transactions(previous_transactions)
          previous_transactions.transmit_pending.update_all(status: :superseded, transmit_action: :no_transmit)
        end

        def validate(params)
          unless params[:affected_policies].is_a?(Array)
            return Failure("Invalid affected_policies: #{params[:affected_policies]}. Please pass in a list of affected_policies.")
          end
          if params[:assistance_year].blank?
            return Failure("Invalid assistance_year: #{params[:assistance_year]}. Please pass in a list of assistance_year.")
          end
          if params[:correlation_id].blank?
            return Failure("Invalid correlation_id: #{params[:correlation_id]}. Please pass in a list of correlation_id.")
          end
          return Failure("Invalid family: #{params[:family]}. Please pass in a list of family.") if params[:family].blank?

          params.merge!({ assistance_year: params[:assistance_year].to_i })
          Success(params)
        end
      end
    end
  end
end
