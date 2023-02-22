# frozen_string_literal: true

FactoryBot.define do
  factory :transactions_transmissions, class: "::Transmittable::TransactionsTransmissions" do
    association :transaction, factory: :transmittable_transaction
  end
end
