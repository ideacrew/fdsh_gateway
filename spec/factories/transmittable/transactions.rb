# frozen_string_literal: true

FactoryBot.define do
  factory :transmittable_transaction, class: "::Transmittable::Transaction" do
    status  { :created }
    transmit_action { :transmit }
  end
end
