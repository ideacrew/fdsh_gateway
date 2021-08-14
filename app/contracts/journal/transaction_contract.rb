# frozen_string_literal: true

module Journal
  # FDSH schema and validation rules for {Journal::Transaction}
  class TransactionContract < Contract
    # @!method call(opts)
    # @param opts [Hash] the parameters to validate using this contract
    # @option opts [Types::String] :correlation_id required
    # @option opts [Array<Journal::Activity>] :activities
    # @return [Dry::Monads::Result]
    params do
      required(:correlation_id).filled(:string)
      optional(:activities).array(Journal::ActivityContract.params)
    end
  end
end
