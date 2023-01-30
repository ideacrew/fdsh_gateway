# frozen_string_literal: true

module Journal
  # FDSH schema and validation rules for {Journal::Transaction}
  class ActivityContract < Contract
    # @!method call(opts)
    # @param opts [Hash] the parameters to validate using this contract
    # @option opts [Types::String] :correlation_id required
    # @option opts [Types::String] :command
    # @option opts [Types::String] :event_key required
    # @option opts [Types::String] :message
    # @option opts [Types::String] :status
    # @return [Dry::Monads::Result]
    params do
      required(:correlation_id).filled(:string)
      optional(:command).maybe(:string)
      required(:event_key).filled(:string)
      optional(:message).maybe(:hash)
      optional(:status).maybe(:string)
      optional(:assistance_year).maybe(:integer)
      optional(:application_hbx_id).maybe(:string)
      optional(:tax_year).maybe(:string)
    end
  end
end
