# frozen_string_literal: true

module Fdsh
  module Jobs
    # create job operation that takes params of key (required), started_at(required), publish_on(required), payload (required)
    class GenerateTransmittablePayload
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        job = yield create_job(values)
        transmission = yield create_transmission(job, values)
        transaction = yield create_transaction(transmission, values)
        get_transmittable_payload(transaction)
      end

      private

      def validate_params(params)
        return Failure('key required') unless params[:key]
        return Failure('started_at required') unless params[:started_at]
        return Failure('publish_on required') unless params[:publish_on]
        return Failure('payload required') unless params[:payload]

        Success(params)
      end

      def create_job(values)
        result = Fdsh::Jobs::FindOrCreateJob.new.call(values)

        result.success? ? Success(result.value!) : result
      end

      def create_transmission(job, values)
        result = Fdsh::Jobs::CreateTransmission.new.call(values.merge({ job: job }))

        result.success? ? Success(result.value!) : result
      end

      def create_transaction(transmission, values)
        result = Fdsh::Jobs::CreateTransaction.new.call(values.merge({ transmission: transmission }))

        result.success? ? Success(result.value!) : result
      end

      def get_transmittable_payload(transaction)
        payload = transaction.payload

        payload.present? ? Success(payload) : Failure("Transaction do not consists of a payload")
      end
    end
  end
end
