# frozen_string_literal: true

module Journal
  # FDSH schema and validation rules for {Journal::Transaction}
  class AptcCsrTaxHouseholdContract < Contract
    # @!method call(opts)
    # @param opts [Hash] the parameters to validate using this contract
    # @option opts [Types::String] :correlation_id required
    # @option opts [Types::String] :command
    # @option opts [Types::String] :event_key required
    # @option opts [Types::String] :message
    # @option opts [Types::String] :status
    # @return [Dry::Monads::Result]
    params do
      optional(:hbx_assigned_id).maybe(:string)
      required(:h41_transmission).maybe(:string)
    end
  end
end
