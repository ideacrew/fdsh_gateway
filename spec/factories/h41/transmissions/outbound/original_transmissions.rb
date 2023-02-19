# frozen_string_literal: true

FactoryBot.define do
  factory :h41_original_transmission, class: "::H41::Transmissions::Outbound::OriginalTransmission" do
    status { :open }

    trait :transmitted do
      status { :transmitted }
    end
  end
end
