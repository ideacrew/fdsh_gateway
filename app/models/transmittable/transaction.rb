# frozen_string_literal: true

module Transmittable
  # A single workflow event instance for transmission to an external service
  class Transaction
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :transmission, class_name: '::Transmittable::Transmission', counter_cache: true
    has_one :subject, class_name: '::Transmittable::Subject'

    field :transmit_action, type: Symbol
    field :status, type: Symbol, default: :created

    field :type, type: Symbol
    field :transaction_errors, type: Hash

    # Persist Transaction-related attributes, e.g., foreign key, associated documents
    # { Transmission, Segment and Transaction ID }
    field :metadata, type: Hash

    # field :started_at, type: DateTime, default: -> { Time.now }
    field :started_at, type: DateTime
    field :end_at, type: DateTime

    def transmit_action=(value)
      unless ::Transmittable::TRANSMIT_ACTION_TYPES.includes?(value)
        raise ArgumentError "must be one of: #{::Transmittable::TRANSMIT_ACTION_TYPES}"
      end
      write_attribute(:transmit_status, value)
    end

    def status=(value)
      raise ArgumentError "must be one of: #{@status_kinds}" unless @status_kinds.includes?(value)

      write_attribute(:status, value)
    end
  end
end
