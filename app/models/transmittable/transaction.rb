# frozen_string_literal: true

module Transmittable
  # A single workflow event instance for transmission to an external service
  class Transaction
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :transactable, polymorphic: true, index: true
    has_many :transactions_transmissions, class_name: 'Transmittable::TransactionsTransmissions'

    field :transmit_action, type: Symbol

    # :transmitted will be the value for status if the transaction is already tranmitted
    field :status, type: Symbol, default: :created

    field :transaction_errors, type: Hash

    # An optional field to persist Transaction-related attributes, e.g., foreign key, associated documents
    # @example
    #   metadata = { original_transaction_path: { transmission_id: "37373737", section_id: 2, transaction_id: 535 } }
    field :metadata, type: Hash

    # field :started_at, type: DateTime, default: -> { Time.now }
    field :started_at, type: DateTime
    field :end_at, type: DateTime

    # Scopes
    scope :errored,          -> { where(:transaction_errors.ne => nil) }
    scope :no_transmit,      -> { where(transmit_action: :no_transmit) }
    scope :transmitted,      -> { where(status: :transmitted) }
    scope :transmit_pending, -> { where(transmit_action: :transmit) }

    # Indexes
    index({ 'status' => 1 })
    index({ 'transaction_errors' => 1 })
    index({ 'transmit_action' => 1 })

    def transmit_action=(value)
      raise ArgumentError "must be one of: #{::Transmittable::TRANSMIT_ACTION_TYPES}" if ::Transmittable::TRANSMIT_ACTION_TYPES.exclude?(value)
      write_attribute(:transmit_action, value)
    end

    def status=(value)
      raise ArgumentError "must be one of: #{::Transmittable::TRANSACTION_STATUS_TYPES}" if ::Transmittable::TRANSACTION_STATUS_TYPES.exclude?(value)
      write_attribute(:status, value)
    end
  end
end
