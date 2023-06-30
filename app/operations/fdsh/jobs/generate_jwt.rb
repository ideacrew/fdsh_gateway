# frozen_string_literal: true

module Fdsh
  module Jobs
    # create job operation that takes params of message_id and correlation_id
    class GenerateJwt
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        job = yield find_job(values[:message_id])
        _transmission = yield create_transmission(job, values[:correlation_id])
        # response = publish_jwt_request(params[:message_id], transmission)
        # response_transmission = yield create_response_transmission(job, params[:correlation_id], response)
        # Success(response)
      end

      private

      def validate_params(params)
        return Failure('message_id required') unless params[:message_id]
        return Failure('correlation_id required') unless params[:correlation_id]

        Success(params)
      end

      def find_job(message_id)
        job = Transmittable::Job.find_by(message_id: message_id)

        job ? Success(job) : Failure("No job exists with the given message_id")
      end

      def create_transmission(job, correlation_id)
        result = Fdsh::Jobs::CreateTransmission.new.call({ job: job,
                                                           key: :jwt_request,
                                                           started_at: DateTime.now,
                                                           event: 'initial',
                                                           state_key: :initial,
                                                           correlation_id: correlation_id })

        result.success? ? Success(result.value!) : result
      end

      def publish_jwt_request(message_id, transmission)
        # TODO
        # create server for jwt service in event source
        # create async_api config in aca entities
        # configure server in fdsh
        # create publish operation in fdsh
        # create subscriber operation in fdsh
        # trigger publish event here!
        # parse response from jwt service
        # create response transmission
      end

    end
  end
end
