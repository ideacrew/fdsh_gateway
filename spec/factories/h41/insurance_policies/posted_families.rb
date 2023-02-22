# frozen_string_literal: true

FactoryBot.define do
  factory :posted_family, class: "::H41::InsurancePolicies::PostedFamily" do
    sequence(:family_hbx_id)    { |n| n + 44_345 }
  end
end
