# frozen_string_literal: true

FactoryBot.define do
  factory :transmittable_transmission, class: "::Transmittable::Transmission" do
    status  { :open }
  end
end
