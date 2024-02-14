# frozen_string_literal: true

module Fdsh
  module Jobs
    # create Transaction that takes params of key (required), started_at(required), and transmission (required)
    class CreateTransaction
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        transaction_hash = yield build_transaction_hash(values)
        transaction_entity = yield create_transaction_entity(transaction_hash)
        transaction = yield create_transaction(transaction_entity, values[:subject])
        _transaction_transmission = yield create_transaction_transmission(transaction, values[:transmission])
        Success(transaction)
      end

      private

      def validate_params(params)
        return Failure('Transaction cannot be created without key symbol') unless params[:key].is_a?(Symbol)
        return Failure('Transaction cannot be created without started_at datetime') unless params[:started_at].is_a?(DateTime)
        return Failure('Transaction cannot be created without a transmission') unless params[:transmission].is_a?(::Transmittable::Transmission)
        return Failure('Transaction cannot be created without a subject') unless params[:subject]
        return Failure('Transaction cannot be created without event string') unless params[:event].is_a?(String)
        return Failure('Transaction cannot be created without state_key symbol') unless params[:state_key].is_a?(Symbol)

        Success(params)
      end

      def build_transaction_hash(values)
        Success({
                  key: values[:key],
                  title: values[:title],
                  description: values[:description],
                  process_status: create_process_status(values[:event], values[:state_key]),
                  started_at: values[:started_at],
                  ended_at: values[:ended_at],
                  transmittable_errors: [],
                  json_payload: values[:json_payload]
                })
      end

      def create_process_status(event, state_key)
        Fdsh::Jobs::CreateProcessStatusHash.new.call({ event: event, state_key: state_key, started_at: DateTime.now,
                                                       message: 'created transaction' }).value!
      end

      def create_transaction_entity(transaction_hash)
        validation_result = AcaEntities::Protocols::Transmittable::Operations::Transactions::Create.new.call(transaction_hash)

        validation_result.success? ? Success(validation_result.value!) : Failure("Unable to create Transaction due to invalid params")
      end

      def create_transaction(transaction_entity, subject)
        transaction = subject.transactions.create(transaction_entity.to_h)

        transaction.persisted? ? Success(transaction) : Failure("Unable to create Transaction due to invalid params")
      end

      def create_transaction_transmission(transaction, transmission)
        result = ::Transmittable::TransactionsTransmissions.create(
          transmission: transmission,
          transaction: transaction
        )
        result.persisted? ? Success(result) : Failure("Unable to create transactions_transmissions due to invalid params")
      end
    end
  end
end