# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Journal
  module Transactions
    # Add an {EventSource::Event} to the transaction journal
    class AddActivity
      include Dry::Monads[:try, :result, :do]

      # @param [Hash] opts The options to create application object
      # @option opts [Hash] :correlation_id
      # @option opts [Hash] :activity
      # @return [Dry::Monads::Result]
      def call(params)
        values = yield validate_params(params)
        transaction = yield find_or_create_transaction(values.to_h)

        Success(transaction)
      end

      private

      # rubocop:disable Style/MultilineBlockChain
      def validate_params(params)
        Try() do
          Journal::ActivityContract.new.call(params[:activity])
        end.bind do |result|
          if result.success?
            Journal::TransactionContract.new.call(
              correlation_id: params[:correlation_id],
              magi_medicaid_application: params[:magi_medicaid_application],
              activities: [result.to_h],
              application_id: params[:application_id],
              primary_hbx_id: params[:primary_hbx_id]
            )
          else
            result
          end
        end
      end
      # rubocop:enable Style/MultilineBlockChain

      def find_or_create_transaction(values)
        Journal::Transactions::FindOrCreate.new.call(values)
      end
    end
  end
end
