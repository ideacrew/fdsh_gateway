# frozen_string_literal: true

module Transmittable
  # A single workflow event instance for transmission to an external service
  class Transaction
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :transactable, polymorphic: true, index: true
    has_many :transactions_transmissions, class_name: 'Transmittable::TransactionsTransmissions'
    has_one :process_status, as: :statusable, class_name: 'Transmittable::ProcessStatus'
    accepts_nested_attributes_for :process_status
    has_many :transmittable_errors, as: :errorable, class_name: 'Transmittable::Error'
    accepts_nested_attributes_for :transmittable_errors

    field :transmit_action, type: Symbol

    # :transmitted will be the value for status if the transaction is already tranmitted
    field :status, type: Symbol, default: :created

    field :transaction_errors, type: Hash, default: {}

    # An optional field to persist Transaction-related attributes, e.g., foreign key, associated documents
    # @example
    #   metadata = { original_transaction_path: { transmission_id: "37373737", section_id: 2, transaction_id: 535 } }
    field :metadata, type: Hash

    # field :started_at, type: DateTime, default: -> { Time.now }
    field :started_at, type: DateTime
    field :end_at, type: DateTime

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :ended_at, type: DateTime
    field :json_payload, type: Hash
    field :xml_payload, type: String

    # Scopes
    scope :blocked,          -> { where(status: :blocked) }
    scope :errored,          -> { where(status: :errored) }
    scope :no_transmit,      -> { where(transmit_action: :no_transmit) }
    scope :superseded,       -> { where(status: :superseded) }
    scope :transmitted,      -> { where(status: :transmitted) }
    scope :transmit_pending, -> { where(transmit_action: :transmit) }

    scope :newest, -> { order(created_at: :desc) }

    # Indexes
    index({ 'status' => 1 })
    index({ 'transaction_errors' => 1 })
    index({ 'transmit_action' => 1 })

    def transmit_action=(value)
      ::Transmittable::Transmission.define_transmission_constants

      if ::Transmittable::DEFAULT_TRANSMIT_ACTION_TYPES.exclude?(value)
        raise ArgumentError "must be one of: #{::Transmittable::DEFAULT_TRANSMIT_ACTION_TYPES}"
      end
      write_attribute(:transmit_action, value)
    end

    def status=(value)
      ::Transmittable::Transmission.define_transmission_constants

      if ::Transmittable::DEFAULT_TRANSACTION_STATUS_TYPES.exclude?(value)
        raise ArgumentError "must be one of: #{::Transmittable::DEFAULT_TRANSACTION_STATUS_TYPES}"
      end
      write_attribute(:status, value)
    end

    def transmission
      transaction_transmission = transactions_transmissions.where(transaction_id: self.id).first
      transaction_transmission.transmission
    end

    def subject_hbx_id
      transactable.has_attribute?(:hbx_id) ? transactable.hbx_id : transactable.hbx_assigned_id
    end

    def transaction_errors=(value)
      raise(ArgumentError, "#{value} must be of type Hash") unless value.is_a?(Hash)

      write_attribute(:transaction_errors, transaction_errors.merge(value))
    end

    def error_messages
      return [] unless errors

      transmittable_errors&.map {|error| "#{error.key}: #{error.message}"}&.join(";")
    end

    def formatted_xml_payload
      return false unless xml_payload
      doc = Nokogiri::XML(xml_payload)
      return if doc.errors
      doc&.to_xhtml(indent: 2)
    end
  end
end
