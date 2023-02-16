# frozen_string_literal: true

FactoryBot.define do
  factory :h41_void_transmission, class: "::H41::Transmissions::Outbound::VoidTransmission" do
    status { :open }

    trait :transmitted do
      status { :transmitted }
    end
  end
end
