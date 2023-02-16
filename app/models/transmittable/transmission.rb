# frozen_string_literal: true

# Design Goals
#   ability to persist uniques data models
#   abstracted approach to Transmission/Transaaction status

# Job - signal transmitted from EA. May include deny_list and allow_list
#   # at least
#   Transmission (types: original, corrected, void)
#     has_many :transactions, class_name: 'SubjectClassName'
#     # transaction subject
#     # zipped (folder) with one manifest, one or more segments (files), one or more transactions/file
#     Transactions

module Transmittable
  # A list of valid status values.  Override defaults using initializer options
  # acked: acknowledged
  # completed: processing of the object finished
  # nacked: negative_acknowledged, an outside service completed processing and indicated an error
  # pending: awaiting processing
  DEFAULT_TRANSACTION_STATUS_TYPES = %i[
    approved
    acked
    created
    completed
    denied
    errored
    excluded
    expired
    failed
    nacked
    pending
    rejected
    submitted
    successful
    superseded
    transmitted
  ].freeze

  DEFAULT_TRANSMISSION_STATUS_TYPES = %i[
    open
    transmitted
  ].freeze

  DEFAULT_TRANSMIT_ACTION_TYPES = %i[blocked expired hold no_transmit pending transmit].freeze

  # Persistence model for all transmissions
  class Transmission
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :account, class_name: 'Accounts::Account', optional: true
    has_many :transactions_transmissions, class_name: 'Transmittable::TransactionsTransmissions'

    # State for the Transmission
    field :status, type: Symbol
    field :started_at, type: DateTime, default: -> { Time.now }
    field :ended_at, type: DateTime

    # Scopes
    scope :open, -> { where(status: :open) }

    # Indexes
    index({ 'open' => 1 })

    # @example
    def initialize(args = nil)
      args ||= { options: {} }
      args.merge!({ options: {} }) unless args.key?(:options)

      super(args.except(:options))

      ::Transmittable.const_set(
        'TRANSACTION_STATUS_TYPES',
        args[:options][:transaction_status_types] || DEFAULT_TRANSACTION_STATUS_TYPES
      )

      ::Transmittable.const_set(
        'TRANSMIT_ACTION_TYPES',
        args[:options][:transmit_action_types] || DEFAULT_TRANSMIT_ACTION_TYPES
      )

      ::Transmittable.const_set(
        'TRANSMISSION_STATUS_TYPES',
        args[:options][:transmission_status_types] || DEFAULT_TRANSMISSION_STATUS_TYPES
      )
    end

    def status=(value)
      unless ::Transmittable::TRANSMISSION_STATUS_TYPES.include?(value)
        raise ArgumentError "must be one of: #{::Transmittable::TRANSMISSION_STATUS_TYPES}"
      end
      write_attribute(:status, value)
    end

    # Returns boolean indicating if all Transaction subjects completed processing
    def complete?
      # code here
    end

    # Returns boolean indicating if any of this transmission's transactions encountered
    # an exception
    def errors?
      self.errors.nil? == false
    end
  end
end
