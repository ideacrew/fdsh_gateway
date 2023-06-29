# frozen_string_literal: true

module Fdsh
  module Jobs
    # create Transaction that takes params of key (required), started_at(required), and transmission (required)
    class CreateTransaction
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        transmittable_payload = yield generate_transmittable_payload(values)
        transaction_hash = yield build_transaction_hash(values, transmittable_payload)
        transaction_entity = yield create_transaction_entity(transaction_hash)
        transaction = yield create_transaction(values[:transmission], transaction_entity)
        _transaction_transmission = yield create_transaction_transmission(transaction, values[:transmission])
        Success(transaction)
      end

      private

      def validate_params(params)
        return Failure('Transaction cannot be created without key symbol') unless params[:key].is_a?(Symbol)
        return Failure('Transaction cannot be created without started_at datetime') unless params[:started_at].is_a?(DateTime)
        return Failure('Transaction cannot be created without a transmission') unless params[:transmission].is_a?(Transmittable::Transmission)

        Success(params)
      end

      def generate_transmittable_payload(values)
        # result = Fdsh::Ssa::H3::TransformPersonToJsonSsa.new.call(values[:payload])

        # result.success? ? Success(result.value!) : Failure("Unable to transform payload to JSON")

        # WIP 
        Success(values[:payload])
      end

      def build_transaction_hash(values, transmittable_payload)
        Success({
                  key: values[:key],
                  title: values[:title],
                  description: values[:description],
                  process_status: create_process_status,
                  started_at: values[:started_at],
                  ended_at: values[:ended_at],
                  errors: [],
                  payload: transmittable_payload
                })
      end

      def create_process_status
        Fdsh::Jobs::CreateProcessStatusHash.new.call({ event: 'initial', state_key: :initial, started_at: DateTime.now }).value!
      end

      def create_transaction_entity(transaction_hash)
        validation_result = AcaEntities::Protocols::Transmittable::Operations::Transactions::Create.new.call(transaction_hash)

        validation_result.success? ? Success(validation_result.value!) : Failure("Unable to create Transaction due to invalid params")
      end

      def create_transaction(_transmission, transaction_entity)
        Success(Transmittable::Transaction.create(transaction_entity.to_h.except(:errors)))
      end

      def create_transaction_transmission(transaction, transmission)
        Success(::Transmittable::TransactionsTransmissions.create(
                  transmission: transmission,
                  transaction: transaction
                ))
      end
    end
  end
end