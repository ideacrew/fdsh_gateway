# frozen_string_literal: true

module Fdsh
  module Jobs
    # create Transaction that takes params of key (required), payload
    class CreateTransaction
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        transaction_hash = build_transaction_hash(values)
        validated_transaction = validate_transaction(transaction_hash)
        _transaction_entity = transaction_entity(validated_transaction)
      end

      private

      def validate_params(params)
        return Failure('key required') unless params[:key]
        return Failure('payload required') unless params[:payload]

        Success(params)
      end

      def build_transaction_hash(values)
        Success({
                  key: values[:key],
                  title: values[:title],
                  description: values[:description],
                  process_status: create_process_status,
                  started_at: DateTime.now,
                  ended_at: values[:ended_at],
                  errors: []
                })
      end

      def initial_process_state
        {
          event: "created",
          message: "",
          started_at: DateTime.now,
          ended_at: nil,
          state_key: :initial
        }
      end

      def create_process_status
        {
          initial_state_key: :initial,
          elapsed_time: 0,
          process_states: [initial_process_state]
        }
      end

      def validate_transaction(transaction_hash)
        validation_result = AcaEntities::Protocols::Transmittable::Contracts::TransactionContract.new.call(transaction_hash)

        validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
      end

      def transaction_entity(validated_transaction)
        AcaEntities::Protocols::Transmittable::Transaction.new(validated_transaction.to_h)
      end
    end
  end
end