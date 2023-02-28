# frozen_string_literal: true

FactoryBot.define do
  factory :h41_aptc_csr_tax_household, class: "::H41::InsurancePolicies::AptcCsrTaxHousehold" do
    association :insurance_policy, factory: :h41_insurance_policy

    sequence(:hbx_assigned_id)    { |n| n + 66_666 }

    transient do
      transmission { nil }
    end

    trait :with_transaction do
      after(:create) do |aptc_csr_tax_household, evaluator|
        create(:transmittable_transaction, :created, :transmit, transactable: aptc_csr_tax_household, transmission: evaluator.transmission)
      end
    end
  end
end
