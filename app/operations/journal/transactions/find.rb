# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Journal
  module Transactions
    # Find a
    class Find
      include Dry::Monads[:result, :do]

      # @param [Hash] opts The options to create application object
      # @option opts [String] :correlation_id
      # @return [Dry::Monads::Result]
      def call(params)
        values = yield validate_params(params)
        document = yield find(values)
        transaction = yield to_entity(document)

        Success(transaction)
      end

      private

      def validate_params(params)
        if params[:correlation_id].nil? || params[:correlation_id].empty?
          Failure('must provide :correlation_id paramater')
        else
          Success(params)
        end
      end

      def find(values)
        transaction =
          ::Transaction.where(correlation_id: values[:correlation_id].to_s)
        if transaction.to_a.empty?
          Failure(
            "Unable to find transaction with correlation_id: #{values[:correlation_id]}"
          )
        else
          Success(transaction.first)
        end
      end

      def to_entity(document)
        Success(document.serializable_hash(except: :_id).deep_symbolize_keys)
      end
    end
  end
end
