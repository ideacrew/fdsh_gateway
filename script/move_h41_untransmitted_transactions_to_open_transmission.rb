# frozen_string_literal: true

# This script moves all H41 un-transmitted original transactions of 2022 original transmitted transmission to 2022 original open transmission.
# bundle exec rails runner script/move_h41_untransmitted_transactions_to_open_transmission.rb

require 'csv'

def find_h41_transmission(status)
  ::Fdsh::H41::Transmissions::Find.new.call(
    {
      reporting_year: 2022,
      status: status,
      transmission_type: :original
    }
  ).success
end

# rubocop:disable Metrics
def process_untransmitted_transactions
  file_name = "#{Rails.root}/move_untransmitted_transcations_#{Date.today.strftime('%Y_%m_%d')}.csv"
  field_names = %w[
    old_transaction_status
    old_transaction_transmit_action
    old_transaction_transmission_reporting_year
    old_transaction_transmission_type
    new_transaction_status
    new_transaction_transmit_action
    new_transaction_transmission_reporting_year
    new_transaction_transmission_type
  ]

  counter = 0
  transmitted_transmission = find_h41_transmission(:transmitted)
  eligible_h41_transactions = transmitted_transmission.transactions.transmit_pending
  open_2022_transission = find_h41_transmission(:open)

  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    @logger.info "Total number of untransmitted transactions: #{eligible_h41_transactions.count}"
    eligible_h41_transactions.no_timeout.each do |old_transaction|
      counter += 1
      @logger.info "---------- Processed #{counter} no. of transactions" if counter % 100 == 0
      @logger.info "----- Processing transaction transmit_action: #{old_transaction.transmit_action}, status: #{old_transaction.status}"
      old_transaction.update_attributes!(status: :superseded, transmit_action: :no_transmit)
      old_aptc_csr_thh = old_transaction.transactable
      old_insurance_policy = old_aptc_csr_thh.insurance_policy
      old_posted_family = old_insurance_policy.posted_family

      posted_family = ::H41::InsurancePolicies::PostedFamily.create(
        contract_holder_id: old_posted_family.contract_holder_id,
        correlation_id: old_posted_family.correlation_id,
        family_cv: old_posted_family.family_cv,
        family_hbx_id: old_posted_family.family_hbx_id
      )

      insurance_policy = posted_family.insurance_policies.create(
        assistance_year: old_insurance_policy.assistance_year,
        policy_hbx_id: old_insurance_policy.policy_hbx_id
      )

      aptc_csr_tax_household = insurance_policy.aptc_csr_tax_households.create(
        corrected: old_aptc_csr_thh.corrected,
        hbx_assigned_id: old_aptc_csr_thh.hbx_assigned_id,
        original: old_aptc_csr_thh.original,
        transaction_xml: old_aptc_csr_thh.transaction_xml,
        void: old_aptc_csr_thh.void
      )

      transaction = aptc_csr_tax_household.transactions.create(
        transmit_action: :transmit,
        status: :created,
        started_at: old_transaction.started_at
      )

      ::Transmittable::TransactionsTransmissions.create!(
        transmission: open_2022_transission,
        transaction: transaction
      )

      csv << [
        old_transaction.status,
        old_transaction.transmit_action,
        old_transaction.transmission.reporting_year,
        old_transaction.transmission._type,
        transaction.status,
        transaction.transmit_action,
        transaction.transmission.reporting_year,
        transaction.transmission._type
      ]

      @logger.info "Processed transaction with tax_household_hbx_assigned_id: #{
        old_aptc_csr_thh.hbx_assigned_id}, policy_hbx_id: #{old_insurance_policy.policy_hbx_id}"
    rescue StandardError => e
      @logger.info "Error raised processing transaction with bson_id: #{
        old_transaction.id}, error: #{e}, backtrace: #{e.backtrace}"
    end
  end
rescue StandardError => e
  @logger.info "Error raised with message: #{e}, backtrace: #{e.backtrace}"
end
# rubocop:enable Metrics

start_time = DateTime.current
@logger = Logger.new("#{Rails.root}/move_untransmitted_transcations_#{Date.today.strftime('%Y_%m_%d')}.log")
@logger.info "Data Migration start_time: #{start_time}"
process_untransmitted_transactions
end_time = DateTime.current
@logger.info "Data Migration end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_i}"
