# frozen_string_literal: true

# This script clones transactions from 2023/03 transmission and 2022/15 transmission into 2023/02 and 2022/14
# bundle exec rails runner script/create_transactions_for_missing_transmission.rb

def fetch_transmission(assistance_year, month)
  find_result = Fdsh::H36::Transmissions::Find.new.call(
    {
      assistance_year: assistance_year,
      month_of_year: month
    }
  )

  raise "No valid_transmission for assistance_year #{assistance_year}, month #{month}" unless find_result.success?

  find_result.success
end

@open_transmission_2022_14 = fetch_transmission(2022, 14)
@open_transmission_2023_2 = fetch_transmission(2023, 2)

@open_transmission_2022_15 = fetch_transmission(2022, 15)
@open_transmission_2023_3 = fetch_transmission(2023, 3)

def check_if_transaction_transmission_exists?(transaction, transmission)
  Transmittable::TransactionsTransmissions.where(transaction_id: transaction.id,
                                                 transmission_id: transmission.id).first.present?
end

def clone_subject_and_create_transaction(transaction)
  subject = transaction.transactable
  irs_group = H36::IrsGroups::IrsGroup.create!(
    correlation_id: subject.correlation_id,
    family_cv: subject.family_cv,
    family_hbx_id: subject.family_hbx_id,
    contract_holder_hbx_id: subject.contract_holder_hbx_id,
    assistance_year: subject.assistance_year
  )
  Transmittable::Transaction.create!(transmit_action: :transmit,
                                     status: :created, started_at: Time.now,
                                     transactable: irs_group)
end

# clone transmit_pending 2022/15 transactions to 2022/14
def clone_2022_15_to_2022_14
  limit = 1000
  offset = 0
  transactions = @open_transmission_2022_15.transactions.transmit_pending
  total_count = transactions.count

  while offset <= total_count
    transactions.offset(offset).limit(limit).no_timeout.each do |transaction|
      next if check_if_transaction_transmission_exists?(transaction, @open_transmission_2022_14)

      new_transaction = clone_subject_and_create_transaction(transaction)
      Transmittable::TransactionsTransmissions.create(
        transmission: @open_transmission_2022_14,
        transaction: new_transaction
      )
    end
    offset += limit
  end
end

# clone transmit_pending 2023/3 transactions to 2023/2
def clone_2023_3_to_2023_2
  limit = 1000
  offset = 0
  transactions = @open_transmission_2023_3.transactions.transmit_pending
  total_count = transactions.count

  while offset <= total_count
    transactions.offset(offset).limit(limit).no_timeout.each do |transaction|
      next if check_if_transaction_transmission_exists?(transaction, @open_transmission_2023_2)

      new_transaction = clone_subject_and_create_transaction(transaction)
      Transmittable::TransactionsTransmissions.create(
        transmission: @open_transmission_2023_2,
        transaction: new_transaction
      )
    end
    offset += limit
  end
end

# move 2022/14 and 2023/2 transactions to pending state
def move_transmission_and_transactions_to_pending
  @open_transmission_2022_14.update!(status: :pending)
  @open_transmission_2023_2.update!(status: :pending)
end

clone_2022_15_to_2022_14
clone_2023_3_to_2023_2
move_transmission_and_transactions_to_pending