# frozen_string_literal: true

FactoryBot.define do
  factory :pdm_manifest do
    batch_ids { ["MyString"] }
    name { "MyString" }
    timestamp { "2022-12-20" }
    response { "MyString" }
    type { "pvc_manifest_type" }
    initial_count { 100 }
    file_generated { false }
    assistance_year { Date.today.year }
  end
end
