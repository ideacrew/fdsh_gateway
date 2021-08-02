# frozen_string_literal: true

module Fdsh
  module Vlp
    module H92
      # Invoke a Initial verification service, and, if appropriate, broadcast the response.
      class HandleInitialVerificationRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @return [Dry::Monads::Result]
        def call(params)
          initial_verification_result_soap = yield RequestInitialVerification.new.call(params[:payload])
          initial_verification_result = yield ::Soap::RemoveSoapEnvelope.new.call(initial_verification_result_soap.body)
          initial_verification_outcome = yield ProcessInitialVerificationResponse.new.call(initial_verification_result)

          event  = yield build_event(params[:correlation_id], initial_verification_outcome)
          result = yield publish(event)

          Success(result)
        end

        protected

        def build_event(correlation_id, initial_verification_outcome)
          payload = initial_verification_outcome.to_h

          event('events.fdsh.initial_verification_complete', attributes: payload, headers: { correlation_id: correlation_id })
        end

        def publish(event)
          event.publish

          Success('Initial verificattion response published successfully')
        end
      end
    end
  end
end