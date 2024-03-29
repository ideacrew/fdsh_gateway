# frozen_string_literal: true

module Fdsh
  module Jobs
    # create Transmission that takes params of key (required), job (required), started_at(required)
    class CreateTransmission
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        transmission_hash = yield build_tranmission_hash(values)
        transmission_entity = yield transmission_entity(transmission_hash)
        tranmission = yield create_transmission(params[:job], transmission_entity)
        Success(tranmission)
      end

      private

      def validate_params(params)
        return Failure('Transmission cannot be created without key symbol') unless params[:key].is_a?(Symbol)
        return Failure('Transmission cannot be created without started_at datetime') unless params[:started_at].is_a?(DateTime)
        return Failure('Transmission cannot be created without a job') unless params[:job].is_a?(Transmittable::Job)
        return Failure('Transmission cannot be created without event string') unless params[:event].is_a?(String)
        return Failure('Transmission cannot be created without state_key symbol') unless params[:state_key].is_a?(Symbol)
        return Failure('Transmission cannot be created without correlation_id string') unless params[:correlation_id].is_a?(String)

        Success(params)
      end

      def build_tranmission_hash(values)
        Success({
                  key: values[:key],
                  title: values[:title],
                  description: values[:description],
                  started_at: values[:started_at],
                  ended_at: values[:ended_at],
                  process_status: create_process_status(values[:event], values[:state_key]),
                  transmission_id: values[:correlation_id],
                  transmittable_errors: []
                })
      end

      def create_process_status(event, state_key)
        Fdsh::Jobs::CreateProcessStatusHash.new.call({ event: event, state_key: state_key, started_at: DateTime.now,
                                                       message: 'created transmission' }).value!
      end

      def transmission_entity(transmission_hash)
        validation_result = AcaEntities::Protocols::Transmittable::Operations::Transmissions::Create.new.call(transmission_hash)

        validation_result.success? ? Success(validation_result.value!) : Failure("Unable to create Transmission due to invalid params")
      end

      def create_transmission(job, tranmission_entity)
        transmission = job.transmissions.new(tranmission_entity.to_h)

        transmission.save ? Success(transmission) : Failure("Failed to save transmission")
      end
    end
  end
end