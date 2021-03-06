# frozen_string_literal: true

module Fdsh
  module Ridp
    module H139
      # Invoke a primary determination service, and, if appropriate, broadcast the response.
      class HandlePrimaryDeterminationRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @return [Dry::Monads::Result]
        def call(params)
          primary_determination_result_soap = yield RequestPrimaryDetermination.new.call(params[:payload])
          primary_determination_result = yield ::Soap::RemoveSoapEnvelope.new.call(primary_determination_result_soap.body)
          primary_determination_outcome = yield ProcessPrimaryResponse.new.call(primary_determination_result)

          event  = yield build_event(params[:correlation_id], primary_determination_outcome)
          result = yield publish(event)

          Success(result)
        end

        protected

        def build_event(correlation_id, primary_determination_outcome)
          payload = primary_determination_outcome.to_h

          event('events.fdsh.primary_determination_complete', attributes: payload, headers: { correlation_id: correlation_id })
        end

        def publish(event)
          event.publish

          Success('Primary determination response published successfully')
        end
      end
    end
  end
end