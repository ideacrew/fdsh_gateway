# frozen_string_literal: true

# This script migrates H41Transactions to new data models
# rails runner script/migrate_h41_transactions.rb

require 'csv'

def find_or_create_policy(posted_family, old_transaction)
  posted_family.reload.insurance_policies.find_or_create_by(
    assistance_year: 2022,
    policy_hbx_id: old_transaction.policy_hbx_id
  )
end

@open_original_transmission = ::Fdsh::H41::Transmissions::FindOrCreate.new.call(
  reporting_year: 2022,
  status: :open,
  transmission_type: :original
).success

file_name = "#{Rails.root}/migrate_h41_transactions_to_new_models_#{Date.today.strftime('%Y_%m_%d')}.csv"
field_names = %w[
  h41_transaction_primary_hbx_id
  h41_transaction_family_hbx_id
  h41_transaction_policy_hbx_id
  h41_transaction_correlation_id
  h41_transaction_bson_id
  posted_family_family_hbx_id
  posted_family_contract_holder_id
  posted_family_policy_hbx_id
  posted_correlation_id
]

counter = 0
total_h41_transactions = H41Transaction.all.count

CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << field_names

  p "Total number of subscribers: #{total_h41_transactions}"

  H41Transaction.all.no_timeout.each do |old_transaction|
    counter += 1

    p "Processed #{counter} of old_transactions" if counter % 50 == 0
    p "----- FamilyHbxID: #{old_transaction.family_hbx_id} - Processing H41Transaction"

    posted_family = ::H41::InsurancePolicies::PostedFamily.create(
      contract_holder_id: old_transaction.primary_hbx_id,
      correlation_id: old_transaction.correlation_id,
      family_cv: old_transaction.cv3_family.to_json,
      family_hbx_id: old_transaction.family_hbx_id
    )

    old_transaction.aptc_csr_tax_households.each do |old_aptc_csr_thh|
      policy = find_or_create_policy(posted_family, old_transaction)

      aptc_csr_tax_household = policy.aptc_csr_tax_households.create(
        hbx_assigned_id: old_aptc_csr_thh.hbx_assigned_id,
        transaction_xml: old_aptc_csr_thh.h41_transmission
      )

      transaction = aptc_csr_tax_household.transactions.create(
        transmit_action: :no_transmit,
        status: :transmitted,
        started_at: old_aptc_csr_thh.created_at
      )

      _join_table = Transmittable::TransactionsTransmissions.create(
        transmission: @open_original_transmission,
        transaction: transaction
      )
      # TODO: Create the TransmissionPath.
      # TODO: Add a field 'is_migrated' on H41Transaction so that if this fails,
      # we can kick of migration again to create these objects in the new model.
    end

    csv << [
      old_transaction.primary_hbx_id,
      old_transaction.family_hbx_id,
      old_transaction.policy_hbx_id,
      old_transaction.correlation_id,
      old_transaction.id.to_s,
      posted_family.family_hbx_id,
      posted_family.contract_holder_id,
      posted_family.insurance_policies.first.policy_hbx_id,
      posted_family.correlation_id

    ]

    p "----- Processed old_transaction with primary_hbx_id: #{old_transaction.primary_hbx_id}"
  rescue StandardError => e
    p "Error raised processing old_transaction with family_hbx_id: #{old_transaction.family_hbx_id}, error: #{e}, backtrace: #{e.backtrace}"
  end
end
