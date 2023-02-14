# frozen_string_literal: true

module Transmittable
  # A single workflow event instance for transmission to an external service
  class Transaction
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :transmission, class_name: '::Transmittable::Transmission', counter_cache: true

    # belongs_to :subject, polymorphic: true
    belongs_to :subject, class_name: 'H41::InsurancePolicies::AptcCsrTaxHousehold'

    field :transmit_action, type: Symbol
    field :status, type: Symbol, default: :created

    # An optional field for Transmissions that have more than one Transaction kind.
    # Restrict to enumerated values by configuring during this Transacation's
    # Transmission initialization
    # @example
    #   Transmission.new(options: { transaction_types: %i[original corrected void] })
    field :type, type: Symbol
    field :transaction_errors, type: Hash

    # An optional field to persist Transaction-related attributes, e.g., foreign key, associated documents
    # @example
    #   metadata = { original_transaction_path: { transmission_id: "37373737", section_id: 2, transaction_id: 535 } }
    field :metadata, type: Hash

    # field :started_at, type: DateTime, default: -> { Time.now }
    field :started_at, type: DateTime
    field :end_at, type: DateTime

    def type=(value)
      raise ArgumentError "must be one of: #{::Transmittable::TRANSACTION_TYPES}" unless ::Transmittable::TRANSACTION_TYPES.includes?(value)
      write_attribute(:transmit_status, value)
    end

    def transmit_action=(value)
      raise ArgumentError "must be one of: #{::Transmittable::TRANSMIT_ACTION_TYPES}" unless ::Transmittable::TRANSMIT_ACTION_TYPES.includes?(value)
      write_attribute(:transmit_status, value)
    end

    def status=(value)
      raise ArgumentError "must be one of: #{@status_kinds}" unless @status_kinds.includes?(value)

      write_attribute(:status, value)
    end
  end
end
