# frozen_string_literal: true

FactoryBot.define do
  factory :h41_original_transmission, class: "::H41::Transmissions::Outbound::OriginalTransmission" do
    reporting_year { Date.today.year }
    status         { :open }

    trait :transmitted do
      status { :transmitted }
    end
  end
end
