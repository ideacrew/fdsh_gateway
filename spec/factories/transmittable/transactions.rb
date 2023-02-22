# frozen_string_literal: true

FactoryBot.define do
  factory :transmittable_transaction, class: "::Transmittable::Transaction" do

    status  { :created }
    transmit_action { :transmit }

    transient do
      transmission { nil }
    end

    trait :created do
      status { :created }
    end

    trait :transmit do
      transmit_action { :transmit }
    end

    trait :with_transmission_path do
      after(:create) do |transaction, evaluator|
        create(:transmission_path, transaction: transaction, transmission: evaluator.transmission)
      end
    end

    after(:create) do |transaction, evaluator|
      create(:transactions_transmissions, transaction: transaction, transmission: evaluator.transmission)
    end
  end
end
