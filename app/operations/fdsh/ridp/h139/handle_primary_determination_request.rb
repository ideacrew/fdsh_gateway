# frozen_string_literal: true

module Fdsh
  module Ridp
    module H139
      # Invoke a primary determination service, and, if appropriate, broadcast the response.
      class HandlePrimaryDeterminationRequest
        include Dry::Monads[:result, :do, :try]

        PublishEventStruct = Struct.new(:name, :payload)

        PUBLISH_EVENT = "primary_determination_complete"

        # @return [Dry::Monads::Result]
        def call(params)
          primary_determination_request = yield RequestPrimaryDetermination.new.call(params[:payload])
          primary_determination_result = yield TransformFamilyToPrimaryDetermination.new.call(primary_determination_request.body)
          publish_response(params[:correlation_id], primary_determination_result)
        end

        protected

        def publish_response(correlation_id, primary_determination_result)
          payload = primary_determination_result.to_json
          event = PublishEventStruct.new(PUBLISH_EVENT, payload)

          Success(Publishers::Fdsh::Eligibilities::RidpPublisher.publish(event, {correlation_id: correlation_id}))
        end

      end
    end
  end
end