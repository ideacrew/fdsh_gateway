# frozen_string_literal: true

module Fdsh
  module NonEsi
    module H31
      # Invoke a Initial verification service, and, if appropriate, broadcast the response.
      class HandleJsonEligibilityDeterminationRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @return [Dry::Monads::Result]
        def call(params)
          validate_params = yield validate_params(params)
          values = yield transmittable_payload(validate_params)
          jwt = yield generate_jwt(values)
          ssa_response = yield publish_ssa_request(params[:correlation_id], jwt)
          ssa_response = yield verify_response(ssa_response)
          _response_transmission = yield create_response_transmission(values, params[:correlation_id])
          _response_transaction = yield create_response_transaction(values, ssa_response)
          transformed_response = yield transform_response
          event  = yield build_event(params[:correlation_id], transformed_response)
          result = yield publish(event)
          Success(result)
        end

        protected

        def validate_params(params)
          return Failure('Cannot process eligibility determination request without correlation id') unless params[:correlation_id].is_a?(String)
          return Failure('Cannot process eligibility determination request without payload') if params[:payload].blank?

          Success(params)
        end

        def transmittable_payload(params)
          result = ::Fdsh::Jobs::GenerateTransmittableNonEsiPayload.new.call({ key: :non_esi_mec_request,
                                                                               title: 'Non Esi Mec Request',
                                                                               description: 'Request for Non esi mec for CMS',
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

        def publish_ssa_request(_correlation_id, _jwt)
          # publish operation
          # result = Fdsh::Ssa::H3::RequestJsonSsaVerification.new.call({ correlation_id: correlation_id, token: jwt,
          #                                                               transmittable_objects: { transaction: @request_transaction,
          #                                                                                        transmission: @request_transmission, job: @job } })
          if result.success?
            status_result = update_status({ transaction: @request_transaction, transmission: @request_transmission }, :acked, "acked from cms")
            return status_result if status_result.failure?
            Success(result.value!)
          else
            add_errors({ transaction: @request_transaction, transmission: @request_transmission, job: @job },
                       "Failed to receive response from cms due to #{result.failure}",
                       :publish_ssa_request)
            status_result = update_status({ transaction: @request_transaction, transmission: @request_transmission, job: @job }, :failed,
                                          "Failed to receive response from cms")
            return status_result if status_result.failure?
            result
          end
        end

        def add_errors(transmittable_objects, message, error_key)
          Fdsh::Jobs::AddError.new.call({ transmittable_objects: transmittable_objects, key: error_key, message: message })
        end

        def verify_response(ssa_response)
          if ssa_response.status == 200
            status_result = update_status({ transaction: @request_transaction, transmission: @request_transmission }, :succeeded,
                                          "Successfully recieved response from cms")
            return status_result if status_result.failure?
            Success(ssa_response)
          else
            add_errors({ transaction: @request_transaction, transmission: @request_transmission, job: @job },
                       "Did not recieve a success response from cms, received status code #{ssa_response.status}",
                       :verify_response)
            status_result = update_status({ transaction: @request_transaction, transmission: @request_transmission, job: @job }, :failed,
                                          "Did not recieve a success response from cms")
            return status_result if status_result.failure?
            Failure(ssa_response)
          end
        end

        def update_status(transmittable_objects, state, message)
          Fdsh::Jobs::UpdateProcessStatus.new.call({ transmittable_objects: transmittable_objects, state: state, message: message })
        end

        def create_response_transmission(values, correlation_id)
          result = Fdsh::Jobs::CreateTransmission.new.call(values.merge({ key: :ssa_verification_response,
                                                                          started_at: DateTime.now,
                                                                          job: @job,
                                                                          event: 'received',
                                                                          state_key: :received,
                                                                          title: 'SSA Verification Response',
                                                                          description: 'Response for SSA verification from CMS',
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

        def create_response_transaction(values, ssa_response)
          subject = values[:transaction].transactable
          result = Fdsh::Jobs::CreateTransaction.new.call(values.merge({ key: :ssa_verification_response,
                                                                         started_at: DateTime.now,
                                                                         transmission: @response_transmission,
                                                                         title: 'SSA Verification Response',
                                                                         description: 'Response for SSA verification from CMS',
                                                                         subject: subject,
                                                                         event: 'received',
                                                                         state_key: :received }))

          if result.success?
            @response_transaction = result.value!
            @response_transaction.json_payload = JSON.parse(ssa_response.env.response_body)
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
          result = AcaEntities::Fdsh::Ssa::H3::Operations::SsaVerificationJsonResponse.new.call(@response_transaction.json_payload)
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

        def build_event(correlation_id, response)
          payload = response.to_h

          event('events.fdsh.ssa_verification_complete', attributes: payload, headers: { correlation_id: correlation_id })
        end

        def publish(event)
          event.publish
          status_result = update_status({ job: @job }, :succeeded, "successfully sent response to EA")
          return status_result if status_result.failure?
          Success('SSA verificattion response published successfully')
        end
      end
    end
  end
end