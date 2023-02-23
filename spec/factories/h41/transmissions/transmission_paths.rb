# frozen_string_literal: true

FactoryBot.define do
  factory :transmission_path, class: "::H41::Transmissions::TransmissionPath" do
    association :transaction, factory: :transmittable_transaction

    batch_reference        { '2023-02-10T21:43:39Z' }
    content_file_id        { '00001' }
    record_sequence_number { '223456000000001' }
  end
end
