# frozen_string_literal: true

module Journal
  # An action or event associated with a single transaction
  class Activity < Dry::Struct
    # @!attribute [r] CorrelationId
    # A requester-assigned ID that identifies the transaction
    # assocaated with this event
    # @return [String]
    attribute :CorrelationId, Types::String.meta(omittable: false)

    # @!attribute [r] CorrelationId
    # Hbx Assigned ID of the application that activity belongs to
    # assocaated with this event
    # @return [String]
    attribute :application_hbx_id, Types::String.meta(omittable: true)

    # @!attribute [r] event_key
    # The name of this event
    # @return [String]
    attribute :event_key, Types::String.meta(omittable: false)

    # @!attribute [r] command
    # The operation name that produced this event
    # @return [String]
    attribute :command, Types::String.meta(omittable: true)

    # @!attribute [r] message
    # The payload associated with this event
    # @return [Hash]
    attribute :message, Types::Hash.meta(omittable: true)

    # @!attribute [r] status
    # A status value result associaated with processing the event
    # @return [String]
    attribute :status, Types::String.meta(omittable: true)

    # @!attribute [r] assistance_year
    # Assistance year of the application
    # @return [Integer]
    attribute :assistance_year, Types::Integer.meta(omittable: true)
  end
end

