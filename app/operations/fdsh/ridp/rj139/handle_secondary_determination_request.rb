# frozen_string_literal: true

module Fdsh
  module Ridp
    module Rj139
      # Send a secondary request to CMS and process response and publish to Enroll
      class HandleSecondaryDeterminationRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @return [Dry::Monads::Result]
        def call(params)
          validate_params = yield validate_params(params)
          values = yield transmittable_payload(validate_params)
          jwt = yield generate_jwt(values)
          ridp_response = yield publish_ridp_secondary_request(params[:correlation_id], jwt)
          ridp_response = yield verify_response(ridp_response)
          _response_transmission = yield create_response_transmission(values, params[:correlation_id])
          _response_transaction = yield create_response_transaction(values, ridp_response)
          transformed_response = yield transform_response
          event  = yield build_event(params[:correlation_id], transformed_response)
          result = yield publish(event)
          Success(result)
        end

        protected

        def validate_params(params)
          return Failure('Cannot process RIDP secondary request without correlation id') unless params[:correlation_id].is_a?(String)
          return Failure('Cannot process RIDP secondary request without session id') unless params[:session_id].is_a?(String)
          return Failure('Cannot process RIDP secondary request without payload') if params[:payload].blank?

          Success(params)
        end

        def transmittable_payload(params)
          result = ::Fdsh::Jobs::GenerateTransmittableRidpSecondaryPayload.new.call({ key: :ridp_secondary_verification_request,
                                                                                      title: 'RIDP Secondary Request',
                                                                                      description: 'RIDP Secondary verification request to CMS',
                                                                                      payload: params[:payload],
                                                                                      correlation_id: params[:correlation_id],
                                                                                      started_at: DateTime.now,
                                                                                      publish_on: DateTime.now,
                                                                                      session_id: params[:session_id]})

          result.success? ? Success(result.value!) : result
        end

        def generate_jwt(values)
          @request_transaction = values[:transaction]
          @request_transmission = @request_transaction.transactions_transmissions.last.transmission
          @job = @request_transmission.job
          result = Jwt::GetJwt.new.call({})

          return result if result.success?

          add_errors({ transaction: @request_transaction, transmission: @request_transmission, job: @job },
                     result.failure,
                     :generate_jwt)
          status_result = update_status({ transaction: @request_transaction, transmission: @request_transmission, job: @job }, :failed,
                                        result.failure)
          return status_result if status_result.failure?
          result
        end

        def publish_ridp_secondary_request(correlation_id, jwt)
          result = Fdsh::Ridp::Rj139::RequestRidpVerification.new.call({ correlation_id: correlation_id, token: jwt,
                                                                         transmittable_objects: { transaction: @request_transaction,
                                                                                                  transmission: @request_transmission,
                                                                                                  job: @job } })
          if result.success?
            status_result = update_status({ transaction: @request_transaction, transmission: @request_transmission }, :acked, "acked from cms")
            return status_result if status_result.failure?
            Success(result.value!)
          else
            add_errors({ transaction: @request_transaction, transmission: @request_transmission, job: @job },
                       "Failed to receive response from cms due to #{result.failure}",
                       :publish_ridp_secondary_request)
            status_result = update_status({ transaction: @request_transaction, transmission: @request_transmission, job: @job }, :failed,
                                          "Failed to receive response from cms")
            return status_result if status_result.failure?
            result
          end
        end

        def verify_response(ridp_response)
          if ridp_response.status == 200
            status_result = update_status({ transaction: @request_transaction, transmission: @request_transmission }, :succeeded,
                                          "Successfully recieved response from cms")
            return status_result if status_result.failure?
            Success(ridp_response)
          else
            add_errors({ transaction: @request_transaction, transmission: @request_transmission, job: @job },
                       "Did not recieve a success response from cms, received status code #{ridp_response.status}",
                       :verify_response)
            status_result = update_status({ transaction: @request_transaction, transmission: @request_transmission, job: @job }, :failed,
                                          "Did not recieve a success response from cms")
            return status_result if status_result.failure?
            Failure(ridp_response)
          end
        end

        def create_response_transmission(values, correlation_id)
          result = Fdsh::Jobs::CreateTransmission.new.call(values.merge({ key: :ridp_secondary_verification_response,
                                                                          started_at: DateTime.now,
                                                                          job: @job,
                                                                          event: 'received',
                                                                          state_key: :received,
                                                                          title: 'RIDP Secondary Verification Response',
                                                                          description: 'Response for secondary RIDP verification from CMS',
                                                                          correlation_id: correlation_id }))

          if result.success?
            @response_transmission = result.value!
            Success(@response_transmission)
          else
            add_errors({ transaction: @request_transaction, transmission: @request_transmission, job: @job },
                       "Failed to create response transmission due to #{result.failure}",
                       :create_response_transmission)
            status_result = update_status({ job: @job }, :failed, "Failed to create response transmission")
            return status_result if status_result.failure?
            result
          end
        end

        def create_response_transaction(values, ridp_response)
          subject = values[:transaction].transactable
          result = Fdsh::Jobs::CreateTransaction.new.call(values.merge({ key: :ridp_secondary_verification_response,
                                                                         started_at: DateTime.now,
                                                                         transmission: @response_transmission,
                                                                         title: 'RIDP Secondary Verification Response',
                                                                         description: 'Response for secondary RIDP verification from CMS',
                                                                         subject: subject,
                                                                         event: 'received',
                                                                         state_key: :received }))

          if result.success?
            @response_transaction = result.value!
            @response_transaction.json_payload = JSON.parse(ridp_response.env.response_body)
            @response_transaction.save
            Success(@response_transaction)
          else
            add_errors({ transaction: @request_transaction, transmission: @request_transmission, job: @job },
                       "Failed to create response transaction due to #{result.failure}",
                       :create_response_transaction)
            status_result = update_status({ transmission: @response_transmission, job: @job }, :failed, "Failed to create response transaction")
            return status_result if status_result.failure?
            result
          end
        end

        def transform_response
          # this operation needs to be created
          result = ::Fdsh::Ridp::Rj139::ProcessSecondaryResponse.new.call(@response_transaction.json_payload)
          status_result = if result.success?
                            update_status({ transaction: @response_transaction, transmission: @response_transmission }, :succeeded,
                                          "successfully transformed response from cms")
                          else
                            add_errors({ transaction: @response_transaction, transmission: @response_transmission, job: @job },
                                       "Failed to transform response from cms due to: #{result.failure}",
                                       :transform_response)
                            update_status({ transaction: @response_transaction, transmission: @response_transmission, job: @job }, :failed,
                                          "Failed to transform response from cms due to: #{result.failure}")
                          end
          return status_result if status_result.failure?
          result
        end

        def add_errors(transmittable_objects, message, error_key)
          Fdsh::Jobs::AddError.new.call({ transmittable_objects: transmittable_objects, key: error_key, message: message })
        end

        def update_status(transmittable_objects, state, message)
          Fdsh::Jobs::UpdateProcessStatus.new.call({ transmittable_objects: transmittable_objects, state: state, message: message })
        end

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