# frozen_string_literal: true

# factory for users
FactoryBot.define do
  factory :user do
    sequence(:email) {|n| "example#{n}@example.com"}
    password { "dfkjghfj!!123" }
  end
end
