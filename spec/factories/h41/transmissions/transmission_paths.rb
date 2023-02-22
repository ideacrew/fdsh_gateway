# frozen_string_literal: true

FactoryBot.define do
  factory :transmission_path, class: "::H41::Transmissions::TransmissionPath" do
    association :transaction, factory: :transmittable_transaction
  end
end
