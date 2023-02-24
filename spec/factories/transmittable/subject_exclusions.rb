# frozen_string_literal: true

FactoryBot.define do
  factory :subject_exclusion, class: "::Transmittable::SubjectExclusion" do

    report_kind  { :h41_1095a }
    subject_name { 'PostedFamily' }
    sequence(:subject_id) { |n| "22222#{n}" }

    trait :active do
      end_at { Time.now + 1.day }
    end

    trait :expired do
      start_at { Time.now - 2.days }
      end_at { Time.now - 1.day }
    end
  end
end
