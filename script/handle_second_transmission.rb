# frozen_string_literal: true

# This script create H41Transactions that are transmitted to CMS the second time and
# creates TransmissionPath objects for transmitted transactions
# bundle exec rails runner script/handle_second_transmission.rb

def find_or_create_h41_transaction(posted_family, insurance_policy)
  H41Transaction.where(policy_hbx_id: insurance_policy.policy_hbx_id).first ||
    H41Transaction.build(
      correlation_id: posted_family.correlation_id,
      primary_hbx_id: posted_family.contract_holder_id,
      family_hbx_id: posted_family.family_hbx_id,
      cv3_family: posted_family.family_cv,
      policy_hbx_id: insurance_policy.policy_hbx_id,
      is_migrated: false,
      transmission_number: 2
    )
end

def process_second_transmission
  transmission = ::H41::Transmissions::Outbound::OriginalTransmission.find('63fac333a559070162647e48')

  transmission.transactions.each do |transaction|
    aptc_csr_thh = transaction.transactable
    insurance_policy = aptc_csr_thh.insurance_policy
    posted_family = insurance_policy.posted_family

    h41_transaction = find_or_create_h41_transaction(posted_family, insurance_policy)

    h41_transaction.aptc_csr_tax_households.build(
      hbx_assigned_id: aptc_csr_thh.hbx_assigned_id,
      h41_transmission: aptc_csr_thh.transaction_xml
    )

    h41_transaction.save!
  rescue StandardError => e
    @logger.info "Error raised processing new transaction with bson_id: #{transaction.id}, error: #{e}, backtrace: #{e.backtrace}"
  end
rescue StandardError => e
  @logger.info "Error raised with message: #{e}, backtrace: #{e.backtrace}"
end

start_time = DateTime.current
@logger = Logger.new("#{Rails.root}/handle_second_transmission_#{Date.today.strftime('%Y_%m_%d')}.log")
@logger.info "Data Migration start_time: #{start_time}"
process_second_transmission
end_time = DateTime.current
@logger.info "Data Migration end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_i}"
