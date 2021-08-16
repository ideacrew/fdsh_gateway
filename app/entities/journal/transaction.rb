# frozen_string_literal: true

module Journal
  # Applicant Information
  class Transaction < Dry::Struct
    # @!attribute [r] CorrelationId
    # A requester-assigned ID that uniquely identifies the transaction
    # @return [String]
    attribute :CorrelationId, Types::String.meta(omittable: false)

    # @!attribute [r] Activities
    #
    # @return [Arry<Transaction>]
    attribute :Activities, Types::Array.of(Activity).meta(omittable: true)
  end
end
