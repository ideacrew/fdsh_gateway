# frozen_string_literal: true

module Fdsh
  module Vlp
    module Rx142
      module InitialVerification
        # Invoke a Initial verification service 142.1, and, if appropriate, broadcast the response.
        class HandleInitialVerificationRequest
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          # @return [Dry::Monads::Result]
          def call(params)
            validate_params = yield validate_params(params)
            values = yield transmittable_payload(validate_params)
            jwt = yield generate_jwt(values)
            response = yield publish_vlp_request(params[:correlation_id], jwt)
            # do we need to do anything with a rest envelop etc?
            # initial_verification_result = yield ::Soap::RemoveSoapEnvelope.new.call(response.body)
            _response_transmission = yield create_response_transmission(values, params[:correlation_id])
            _response_transaction = yield create_response_transaction(values, response)
            initial_verification_outcome = yield process_response(response)
            event  = yield build_event(params[:correlation_id], initial_verification_outcome)
            result = yield publish(event)

            Success(result)
          end

          protected

          def validate_params(params)
            return Failure('Cannot process VLP request without correlation id') unless params[:correlation_id].is_a?(String)
            return Failure('Cannot process VLP request without payload') if params[:payload].blank?

            Success(params)
          end

          def transmittable_payload(params)
            result = ::Fdsh::Jobs::Vlp::GenerateTransmittableInitialVerificationPayload.new.call({ key: :vlp_verification_request,
                                                                                                   title: 'VLP Verification Request',
                                                                                                   description: 'Request for VLP verification to CMS',
                                                                                                   payload: params[:payload],
                                                                                                   correlation_id: params[:correlation_id],
                                                                                                   started_at: DateTime.now,
                                                                                                   publish_on: DateTime.now })

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

          def publish_vlp_request(correlation_id, jwt)
            result = Fdsh::Vlp::Rx142::InitialVerification::RequestInitialVerification.new.call(
              { correlation_id: correlation_id, token: jwt,
                transmittable_objects: { transaction: @request_transaction,
                                         transmission: @request_transmission, job: @job } }
            )
            if result.success?
              status_result = update_status({ transaction: @request_transaction, transmission: @request_transmission }, :acked, "acked from cms")
            else
              add_errors({ transaction: @request_transaction, transmission: @request_transmission, job: @job },
                         "Failed to receive response from cms due to #{result.failure}",
                         :publish_vlp_request)
              status_result = update_status({ transaction: @request_transaction, transmission: @request_transmission, job: @job }, :failed,
                                            "Failed to receive response from cms")
            end
            return status_result if status_result.failure?
            result
          end

          def create_response_transmission(values, correlation_id)
            result = Fdsh::Jobs::CreateTransmission.new.call(values.merge({ key: :vlp_verification_response,
                                                                            started_at: DateTime.now,
                                                                            job: @job,
                                                                            event: 'received',
                                                                            state_key: :received,
                                                                            title: 'VLP Verification Response',
                                                                            description: 'Response for VLP verification from CMS',
                                                                            correlation_id: correlation_id }))

            if result.success?
              @response_transmission = result.value!
            else
              add_errors({ transaction: @request_transaction, transmission: @request_transmission, job: @job },
                         "Failed to create response transmission due to #{result.failure}",
                         :create_response_transmission)
              status_result = update_status({ job: @job }, :failed, "Failed to create response transmission")
              return status_result if status_result.failure?
            end
            result
          end

          def create_response_transaction(values, vlp_response)
            subject = values[:transaction].transactable
            result = Fdsh::Jobs::CreateTransaction.new.call(values.merge({ key: :vlp_verification_response,
                                                                           started_at: DateTime.now,
                                                                           transmission: @response_transmission,
                                                                           title: 'VLP Verification Response',
                                                                           description: 'Response for VLP verification from CMS',
                                                                           subject: subject,
                                                                           event: 'received',
                                                                           state_key: :received }))

            if result.success?
              @response_transaction = result.value!
              # this is best guess, will need to verify when testing locally.
              @response_transaction.xml_payload = vlp_response.env.response_body
              @response_transaction.save
            else
              add_errors({ transaction: @request_transaction, transmission: @request_transmission, job: @job },
                         "Failed to create response transaction due to #{result.failure}",
                         :create_response_transaction)
              status_result = update_status({ transmission: @response_transmission, job: @job }, :failed, "Failed to create response transaction")
              return status_result if status_result.failure?
            end
            result
          end

          def process_response(response)
            result = ProcessInitialVerificationResponse.new.call(response)

            if result.success?
              status_result = update_status({ transaction: @response_transaction, transmission: @response_transmission }, :succeeded,
                                            "processed the payload from VLP")
            else
              add_errors({ transaction: @response_transaction, transmission: @response_transmission, job: @job },
                         "Failed to process response from cms due to #{result.failure}",
                         :process_response)
              status_result = update_status({ transaction: @response_transaction, transmission: @response_transmission, job: @job }, :failed,
                                            "Failed to process response from cms")
            end
            return status_result if status_result.failure?
            result
          end

          def build_event(correlation_id, initial_verification_outcome)
            payload = initial_verification_outcome.to_h

            event('events.fdsh.initial_verification_complete', attributes: payload, headers: { correlation_id: correlation_id })
          end

          def publish(event)
            event.publish
            status_result = update_status({ job: @job }, :succeeded, "successfully sent response to EA")
            return status_result if status_result.failure?

            Success('Initial REST XML verification response published successfully')
          end

          def add_errors(transmittable_objects, message, error_key)
            Fdsh::Jobs::AddError.new.call({ transmittable_objects: transmittable_objects, key: error_key, message: message })
          end

          def update_status(transmittable_objects, state, message)
            Fdsh::Jobs::UpdateProcessStatus.new.call({ transmittable_objects: transmittable_objects, state: state, message: message })
          end
        end
      end
    end
  end
end