# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    sequence(:correlation_id) {|n| "id_#{n}"}
  end

  trait :with_activity do
    after :build do |transaction, evaluator|
      transaction.activities << build(:activity, correlation_id: evaluator.correlation_id)
    end
  end
end