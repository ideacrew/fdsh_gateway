# frozen_string_literal: true

module Fdsh
  module Jobs
    # create Transmission that takes params of key (required), payload
    class CreateTransmission
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        transmission_hash = build_tranmission_hash(values)
        validated_transmission = validate_transmission(transmission_hash)
        _transmission_entity = transmission_entity(validated_transmission)
        _transactions = build_transactions(values[:key], values[:payload])
      end

      private

      def validate_params(params)
        return Failure('key required') unless params[:key]
        return Failure('payload required') unless params[:payload]

        Success(params)
      end

      def build_tranmission_hash(values)
        Success({
                  key: values[:key],
                  title: values[:title],
                  description: values[:description],
                  started_at: DateTime.now,
                  ended_at: values[ended_at],
                  process_status: create_process_status,
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

      def validate_transmission(transmission_hash)
        validation_result = AcaEntities::Protocols::Transmittable::Contracts::TransmissionContract.new.call(transmission_hash)

        validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
      end

      def transmission_entity(validated_transmission)
        AcaEntities::Protocols::Transmittable::Transmission.new(validated_transmission.to_h)
      end

      def build_transactions(key, payload)
        ::Fdsh::Jobs::CreateTransaction.new.call({ key: key, payload: payload })
      end
    end
  end
end