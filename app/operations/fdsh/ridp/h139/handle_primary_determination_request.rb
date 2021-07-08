# frozen_string_literal: true

module Fdsh
  module Ridp
    module H139
      # Invoke a primary determination service, and, if appropriate, broadcast the response.
      class HandlePrimaryDeterminationRequest
        include Dry::Monads[:result, :do, :try]

        PublishEventStruct = Struct.new(:name, :payload, :headers)

        PUBLISH_EVENT = "primary_determination_complete"

        # @return [Dry::Monads::Result]
        def call(params)
          primary_determination_result_soap = yield RequestPrimaryDetermination.new.call(params[:payload])
          primary_determination_result = yield ::Soap::RemoveSoapEnvelope.new.call(primary_determination_result_soap.body)
          primary_determination_outcome = yield ProcessPrimaryResponse.new.call(primary_determination_result)

          publish_response(params[:correlation_id], primary_determination_outcome)
        end

        protected

        def publish_response(correlation_id, primary_determination_outcome)
          payload = primary_determination_outcome.to_json
          event = PublishEventStruct.new(PUBLISH_EVENT, payload, { correlation_id: correlation_id })

          Success(Publishers::Fdsh::Eligibilities::RidpPublisher.publish(event))
        end

      end
    end
  end
end