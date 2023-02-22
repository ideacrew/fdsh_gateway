# frozen_string_literal: true

FactoryBot.define do
  factory :month_of_year_transmission, class: "::H36::Transmissions::Outbound::MonthOfYearTransmission" do
    status { :open }

    trait :transmitted do
      status { :transmitted }
    end
  end
end
