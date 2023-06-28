# frozen_string_literal: true

module Fdsh
  module Jobs
    # create job operation that takes params of key (required), started_at(required), publish_on(required)
    class CreateJob
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        job_hash = yield create_job_hash(values)
        job_entity = yield create_job_entity(job_hash)
        job = yield create_job(job_entity)
        Success(job)
      end

      private

      def validate_params(params)
        return Failure('key required') unless params[:key]
        return Failure('started_at required') unless params[:started_at]
        return Failure('publish_on required') unless params[:publish_on]

        Success(params)
      end

      def create_job_hash(values)
        Success({
                  job_id: generate_job_id(values[:key]),
                  saga_id: values[:saga_id],
                  key: values[:key],
                  title: values[:title],
                  description: values[:description],
                  publish_on: values[:publish_on],
                  expire_on: values[:expire_on],
                  started_at: values[:started_at],
                  ended_at: values[:ended_at],
                  time_to_live: values[:time_to_live],
                  process_status: create_process_status,
                  errors: [],
                  allow_list: [],
                  deny_list: []
                })
      end

      def create_job_entity(job_hash)
        validation_result = AcaEntities::Protocols::Transmittable::Operations::Jobs::Create.new.call(job_hash)

        validation_result.success? ? Success(validation_result.value!) : Failure("Unable to create job due to invalid params")
      end

      def generate_job_id(key)
        "#{key}_#{DateTime.now.strftime('%Y%m%d%H%M%S%L')}"
      end

      def create_process_status
        Fdsh::Jobs::CreateProcessStatusHash.new.call({ event: 'initial', state_key: :initial, started_at: DateTime.now }).value!
      end

      def create_job(job_entity)
        Success(Transmittable::Job.create(job_entity.to_h.except(:errors)))
      end
    end
  end
end
