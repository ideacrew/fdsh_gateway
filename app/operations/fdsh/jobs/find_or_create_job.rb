# frozen_string_literal: true

module Fdsh
  module Jobs
    # create job operation that takes params of job_id (optional), key (required), title (optional), description (optional), time_to_live (optional)
    class FindOrCreateJob
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        job_hash = yield find_or_create_job(values)
        validated_job = yield validate_job_hash(job_hash)
        job_entity = yield create_job_entity(validated_job)
        _transmissions = ::Fdsh::Jobs::CreateTransmission.new.call({ key: "#{job_entity.to_h[:key]}_transmission", payload: payload })
        # create_job
        Success(job)
      end

      def validate_params(params)
        return Failure('key required') unless params[:key]
        return Failure('payload required') unless params[:payload]

        Success(params)
      end

      def find_or_create_job(values)
        if values[:job_id]
          find_job(values[:job_id]) # should return a json
        else
          create_job_hash(values)
        end
      end

      def create_job_hash(values)
        Success({
                  job_id: generate_job_id(values[:key]),
                  key: values[:key],
                  title: values[:title],
                  description: values[:description],
                  publish_on: Date.today,
                  expire_on: nil,
                  started_at: DateTime.now,
                  ended_at: nil,
                  time_to_live: values[:time_to_live] || 0,
                  transmissions: [],
                  process_status: create_process_status,
                  errors: [],
                  allow_list: [],
                  deny_list: []
                })
      end

      def validate_job_hash(job_hash)
        validation_result = AcaEntities::Protocols::Transmittable::Contracts::JobContract.new.call(job_hash)

        validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
      end

      def create_job_entity(valid_job_hash)
        ::AcaEntities::Protocols::Transmittable::Job.new(valid_job_hash.to_h)
      end

      def create_job(job_hash)
        creation_result = Try do
          AcaEntities::Protocols::Transmittable::Job.new(job_hash)
        end

        creation_result.or do |e|
          Failure(e)
        end
      end

      def find_job(job_id)
        # to do: implement find job
      end

      def generate_job_id(key)
        # this is a placeholder for now until we figure out how we want to generate the job id
        "#{key}_#{DateTime.now.strftime('%Y%m%d%H%M%S%L')}"
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
    end
  end
end
