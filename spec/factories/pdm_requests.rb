# frozen_string_literal: true

FactoryBot.define do
  factory :pdm_request do
    subject_id { "MyString" }
    command { "MyString" }
    event_key { "MyString" }
    request_payload { "MyString" }
    response_payload { "MyString" }
  end
end
