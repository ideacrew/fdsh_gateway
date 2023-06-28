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
        return Failure('Cannot create a transmission without a job') unless params[:job].is_a?(Transmittable::Job)

        Success(params)
      end

      def build_tranmission_hash(values)
        Success({
                  key: values[:key],
                  title: values[:title],
                  description: values[:description],
                  started_at: values[:started_at],
                  ended_at: values[:ended_at],
                  process_status: create_process_status,
                  errors: []
                })
      end

      def create_process_status
        Fdsh::Jobs::CreateProcessStatusHash.new.call({ event: 'initial', state_key: :initial, started_at: DateTime.now }).value!
      end

      def transmission_entity(transmission_hash)
        validation_result = AcaEntities::Protocols::Transmittable::Operations::Transmissions::Create.new.call(transmission_hash)

        validation_result.success? ? Success(validation_result.value!) : Failure("Unable to create Transmission due to invalid params")
      end

      def create_transmission(job, tranmission_entity)
        Success(job.transmissions.create(tranmission_entity.to_h.except(:errors)))
      end
    end
  end
end