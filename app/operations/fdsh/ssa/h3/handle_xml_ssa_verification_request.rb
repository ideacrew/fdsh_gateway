# frozen_string_literal: true

module Fdsh
  module Ssa
    module H3
      # Invoke a Initial verification service, and, if appropriate, broadcast the response.
      class HandleXmlSsaVerificationRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @return [Dry::Monads::Result]
        def call(params)
          ssa_verification_result_soap = yield RequestXmlSsaVerification.new.call(params[:payload])
          ssa_verification_result = yield ::Soap::RemoveSoapEnvelope.new.call(ssa_verification_result_soap.body)
          ssa_verification_outcome = yield ProcessSsaVerificationResponse.new.call(ssa_verification_result)

          event  = yield build_event(params[:correlation_id], ssa_verification_outcome)
          result = yield publish(event)

          Success(result)
        end

        protected

        def build_event(correlation_id, initial_verification_outcome)
          payload = initial_verification_outcome.to_h

          event('events.fdsh.ssa_verification_complete', attributes: payload, headers: { correlation_id: correlation_id })
        end

        def publish(event)
          event.publish

          Success('SSA verificattion response published successfully')
        end
      end
    end
  end
end