# frozen_string_literal: true

FactoryBot.define do
  factory :h41_original_transmission, class: "::H41::OriginalTransmission" do

    after(:create) do |original_transmission, evaluator|
      original_transmission.build_communication({ options: {} })
    end
  end
end
