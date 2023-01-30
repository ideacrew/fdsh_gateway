# frozen_string_literal: true

module Journal
  # FDSH schema and validation rules for {Journal::Transaction}
  class TransactionContract < Contract
    # @!method call(opts)
    # @param opts [Hash] the parameters to validate using this contract
    # @option opts [Types::String] :correlation_id required
    # @option opts [Array<Journal::Activity>] :activities
    # @option opts [Types::String] :magi_medicaid_application
    # @option opts [Types::String] :application_id
    # @option opts [Types::String] :primary_hbx_id
    # @return [Dry::Monads::Result]
    params do
      required(:correlation_id).filled(:string)
      optional(:magi_medicaid_application).maybe(:string)
      optional(:activities).array(Journal::ActivityContract.params)
      optional(:application_id).maybe(:string)
      optional(:primary_hbx_id).maybe(:string)
      optional(:cv3_family).maybe(:string)
      optiona(:family_hbx_id).maybe(:string)
    end
  end
end
