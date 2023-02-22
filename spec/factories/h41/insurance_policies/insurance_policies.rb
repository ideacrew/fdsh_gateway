# frozen_string_literal: true

FactoryBot.define do
  factory :h41_insurance_policy, class: "::H41::InsurancePolicies::InsurancePolicy" do

    sequence(:policy_hbx_id)    { |n| n + 12_345 }
    assistance_year    { Date.today.year }
    association :posted_family, factory: :posted_family

    transient do
      transaction_xml { '' }
      transmission { nil }
    end

    trait :with_aptc_csr_tax_households do
      after(:create) do |insurance_policy, evaluator|
        create(:h41_aptc_csr_tax_household, :with_transaction, insurance_policy: insurance_policy, transaction_xml: evaluator.transaction_xml,
                                                               transmission: evaluator.transmission)
      end
    end
  end
end

