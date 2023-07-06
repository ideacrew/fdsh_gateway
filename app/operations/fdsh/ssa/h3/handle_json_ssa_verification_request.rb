# frozen_string_literal: true

module Fdsh
  module Ssa
    module H3
      # Invoke a Initial verification service, and, if appropriate, broadcast the response.
      class HandleJsonSsaVerificationRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @return [Dry::Monads::Result]
        def call(params)
          values = yield transmittable_payload(params)
          # jwt = yield generate_jwt(values[:message_id], params[:correlation_id])
          # ssa_verification_result_soap = yield RequestJsonSsaVerification.new.call(params[:payload], params[:correlation_id], jwt)
          # TODO: here
          # ssa_response_verification = to_validate_bearer_token
          # ssa_verification_outcome = process_ssa_verification

          # TODO: be removed once the todo is done.
          # ssa_verification_result = yield ::Soap::RemoveSoapEnvelope.new.call(ssa_verification_result_soap.body)
          # ssa_verification_outcome = yield ProcessSsaVerificationResponse.new.call(ssa_verification_result)

          # event  = yield build_event(params[:correlation_id], ssa_verification_outcome)
          # result = yield publish(event)

          Success(values)
        end

        protected

        def transmittable_payload(params)
          result = ::Fdsh::Jobs::GenerateTransmittableSsaPayload.new.call({ key: :ssa_verification_request,
                                                                            title: 'SSA Verification Request',
                                                                            description: 'Request for SSA verification to CMS',
                                                                            payload: params[:payload],
                                                                            correlation_id: params[:correlation_id],
                                                                            started_at: DateTime.now,
                                                                            publish_on: DateTime.now })

          result.success? ? Success(result.value!) : result
        end

        def generate_jwt(message_id, correlation_id)
          ::Fdsh::Jobs::GenerateJwt.new.call(message_id: message_id, correlation_id: correlation_id)
        end

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