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
          jwt = yield generate_jwt
          ssa_response = yield publish_ssa_request(values, params[:correlation_id], jwt)
          ssa_response = yield verify_response(values, ssa_response)
          response_transmission = yield create_response_transmission(values, params[:correlation_id])
          response_transaction = yield create_response_transaction(values, ssa_response, response_transmission)
          transformed_response = yield transform_response(ssa_response, response_transaction, response_transmission)
          event  = yield build_event(params[:correlation_id], transformed_response)
          result = yield publish(event)
          Success(result)
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

        def generate_jwt
          Jwt::GetJwt.new.call({})
        end

        def publish_ssa_request(values, correlation_id, jwt)
          transaction = values[:transaction]
          transmission = transaction.transactions_transmissions.last.transmission
          result = Fdsh::Ssa::H3::RequestJsonSsaVerification.new.call({ values: values, correlation_id: correlation_id, token: jwt })
          update_status(transaction, transmission, :transmitted, "transmitted to cms")
          result.success? ? Success(result.value!) : result
        end

        def verify_response(values, ssa_response)
          transmission = values[:transaction].transactions_transmissions.last.transmission
          if ssa_response[:status] == 200
            update_status(values[:transaction], transmission, :succeeded, "successfully recieved response from cms")
            Success(ssa_response)
          else
            update_status(values[:transaction], transmission, :failed, "failed response from cms")
            Failure(ssa_response)
          end
        end

        def update_status(transaction, transmission, state, message)
          transaction.process_status.latest_state = state
          transaction.process_status.process_states << Transmittable::ProcessState.new(event: state.to_s,
                                                                                        message: message,
                                                                                        started_at: DateTime.now,
                                                                                        state_key: state)
          transaction.save

          transmission.process_status.latest_state = state
          transmission.process_status.process_states << Transmittable::ProcessState.new(event: state.to_s,
                                                                                        message: message,
                                                                                        started_at: DateTime.now,
                                                                                        state_key: state)
          transmission.save

          transmission.job.process_status.latest_state = state
          transmission.job.process_status.process_states << Transmittable::ProcessState.new(event: state.to_s,
                                                                                            message: message,
                                                                                            started_at: DateTime.now,
                                                                                            state_key: state)
          transmission.job.save
        end

        def create_response_transmission(values, correlation_id)
          job = values[:transaction].transactions_transmissions.last.transmission.job
          result = Fdsh::Jobs::CreateTransmission.new.call(values.merge({ key: :ssa_verification_request,
                                                                          started_at: DateTime.now,
                                                                          job: job,
                                                                          event: 'received',
                                                                          state_key: :received,
                                                                          correlation_id: correlation_id }))

          result.success? ? Success(result.value!) : result
        end

        def create_response_transaction(values, ssa_response, transmission)
          subject = values[:transaction].transactable
          result = Fdsh::Jobs::CreateTransaction.new.call(values.merge({ key: :ssa_verification_request,
                                                                         started_at: DateTime.now,
                                                                         transmission: transmission,
                                                                         subject: subject,
                                                                         event: 'received',
                                                                         state_key: :received }))

          if result.success?
            response_transaction = result.value!
            response_transaction.json_payload = ssa_response
            response_transaction.save
            Success(response_transaction)
          else
            result
          end
        end

        def transform_response(ssa_response, transaction, transmission)
          result = AcaEntities::Fdsh::Ssa::H3::Operations::SsaVerificationJsonResponse.new.call(person)
          if result.success?
            update_status(transaction, transmission, :succeeded, "successfully transformed response from cms")
          else
            update_status(transaction, transmission, :succeeded, "failed to transform response from cms due to: #{result.failure}")
          end
          result
        end

        def build_event(correlation_id, response)
          payload = response.to_h

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