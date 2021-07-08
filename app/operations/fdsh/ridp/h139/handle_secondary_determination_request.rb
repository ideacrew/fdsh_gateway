# frozen_string_literal: true

module Fdsh
  module Ridp
    module H139
      # Invoke a secondary determination service, and, if appropriate, broadcast the response.
      class HandleSecondaryDeterminationRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @return [Dry::Monads::Result]
        def call(params)
          secondary_determination_result_soap = yield RequestSecondaryDetermination.new.call(params[:payload])
          secondary_determination_result = yield ::Soap::RemoveSoapEnvelope.new.call(secondary_determination_result_soap.body)
          secondary_determination_outcome = yield ProcessSecondaryResponse.new.call(secondary_determination_result)

          event  = yield build_event(params[:correlation_id], secondary_determination_outcome)
          result = yield publish(event)

          Success(result)
        end

        protected

        def build_event(correlation_id, secondary_determination_outcome)
          payload = secondary_determination_outcome.to_h

          event('events.fdsh.secondary_determination_complete', attributes: payload, headers: { correlation_id: correlation_id })
        end

        def publish(event)
          event.publish

          Success('Primary determination response published successfully')
        end
      end
    end
  end
end