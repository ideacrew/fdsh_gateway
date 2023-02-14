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

    # :transmitted will be the value for status if the transaction is already tranmitted
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

    # Scopes
    scope :transmitted_originals, ->(subject_id) { where(type: :original, status: :transmitted, subject_id: subject_id) }
    scope :untransmitted, ->(subject_id) { where(transmit_action: :transmit, subject_id: subject_id) }

    # Indexes
    index({ 'type' => 1,  'status' => 1, 'subject_id' => 1 }, { name: 'transmitted_original_transactions' })
    index({ 'transmit_action' => 1, 'subject_id' => 1 }, { name: 'untransmitted_transactions' })

    def type=(value)
      raise ArgumentError "must be one of: #{::Transmittable::TRANSACTION_TYPES}" unless ::Transmittable::TRANSACTION_TYPES.includes?(value)
      write_attribute(:transmit_status, value)
    end

    def transmit_action=(value)
      raise ArgumentError "must be one of: #{::Transmittable::TRANSMIT_ACTION_TYPES}" unless ::Transmittable::TRANSMIT_ACTION_TYPES.includes?(value)
      write_attribute(:transmit_status, value)
    end

    def status=(value)
      unless ::Transmittable::TRANSACTION_STATUS_TYPES.includes?(value)
        raise ArgumentError "must be one of: #{::Transmittable::TRANSACTION_STATUS_TYPES}"
      end

      write_attribute(:status, value)
    end
  end
end
