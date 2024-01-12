# frozen_string_literal: true

FactoryBot.define do
  factory :saa_person, class: "::Ssa::Person" do
    correlation_id {"test_person_123"}
    hbx_id {"12348"}
    encrypted_ssn {"jsabcsdinc"}
    surname {"last_name"}
    given_name {"First_name"}
    dob {"2020-01-01"}
  end

  factory :transmittable_person, class: "::Transmittable::Person" do
    correlation_id {"test_person_123"}
    hbx_id {"12348"}
    encrypted_ssn {"jsabcsdinc"}
    surname {"last_name"}
    given_name {"First_name"}
    dob {"2020-01-01"}
  end
end
