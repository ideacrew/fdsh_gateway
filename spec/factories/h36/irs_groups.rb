# frozen_string_literal: true

FactoryBot.define do
  factory :h36_irs_group, class: "::H36::IrsGroups::IrsGroup" do
    correlation_id { SecureRandom.uuid }
    sequence(:family_hbx_id) {|n| "100#{n}"}
    sequence(:contract_holder_hbx_id) {|n| "1000#{n}" }
    family_cv { {} }
  end
end
