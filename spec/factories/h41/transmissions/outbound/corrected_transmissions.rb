# frozen_string_literal: true

FactoryBot.define do
  factory :h41_corrected_transmission, class: "::H41::Transmissions::Outbound::CorrectedTransmission" do
    status { :open }

    trait :transmitted do
      status { :transmitted }
    end
  end
end
