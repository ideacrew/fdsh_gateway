# frozen_string_literal: true

module Journal
  # FDSH schema and validation rules for {Journal::H41Transaction}
  class H41TransactionContract < Contract
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
      optional(:activities).array(Journal::ActivityContract.params)
      optional(:primary_hbx_id).maybe(:string)
      optional(:cv3_family).maybe(:string)
      optional(:family_hbx_id).maybe(:string)
      optional(:policy_hbx_id).maybe(:string)
      optional(:aptc_csr_tax_households).array(Journal::AptcCsrTaxHouseholdContract.params)
    end
  end
end
