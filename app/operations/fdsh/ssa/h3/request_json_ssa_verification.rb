# frozen_string_literal: true

module Fdsh
  module Ssa
    module H3
      # This class takes a json representing a person as input and invokes SSA.
      class RequestJsonSsaVerification
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param token [Sting] the jwt token for CMS auth
        # @param transmittable_objects [Hash] the transmittable objects that need to be updated w/ successes/failures
        # @param correlation_id [Sting] the correlation id of the subject
        # @return [Dry::Monads::Result]
        def call(params)
          yield validate_params(params)
          event = yield build_event(params)
          publish_event(event, params[:transmittable_objects])
        end

        protected

        def validate_params(params)
          return Failure('Cannot publish payload without transmittable objects') unless params[:transmittable_objects]
          unless params[:transmittable_objects][:transaction].is_a?(::Transmittable::Transaction)
            return Failure('Cannot publish payload without transaction')
          end
          unless params[:transmittable_objects][:transmission].is_a?(::Transmittable::Transmission)
            return Failure('Cannot publish payload without transaction')
          end
          return Failure('Cannot publish payload without transaction') unless params[:transmittable_objects][:job].is_a?(::Transmittable::Job)
          return Failure('Cannot publish payload without correlation_id') unless params[:correlation_id].is_a?(String)
          return Failure('Cannot publish payload without jwt token') unless params[:token].is_a?(String)
          return Failure('Cannot publish payload without transaction json payload') unless params[:transmittable_objects][:transaction].json_payload
          return Failure('Cannot publish payload without message id') unless params[:transmittable_objects][:job].message_id

          Success(params)
        end

        def build_event(params)
          headers = { authorization: "Bearer #{params[:token]}",
                      messageid: params[:transmittable_objects][:job].message_id,
                      partnerid: ENV.fetch('CMS_PARTNER_ID', nil) }
          event = event('events.fdsh.ssa_verification_requested', attributes: params[:transmittable_objects][:transaction].json_payload.to_h,
                                                                  headers: headers)

          return event if event.success?

          add_errors(params[:transmittable_objects],
                     "Failed to build event due to #{event.failure}",
                     :build_ssa_request)
          status_result = Fdsh::Jobs::UpdateProcessStatus.new.call(params[:transmittable_objects], :failed,
                                                                   "Failed to build event")
          return status_result if status_result.failure?
          event
        end

        def publish_event(event, transmittable_hash)
          Success(event.publish)
        rescue StandardError => e
          add_errors(transmittable_hash,
                     "Failed to publish event to CMS due to #{e.message}",
                     :publish_ssa_request)
          Fdsh::Jobs::UpdateProcessStatus.new.call(transmittable_hash, :failed,
                                                   "Failed to publish event to CMS")
          Failure("failed to publish event")
        end

        def update_status(transmittable_hash)
          Fdsh::Jobs::UpdateProcessStatus.new.call({ transmittable_objects: transmittable_hash, state: :transmitted,
                                                     message: "transmitted to cms" })
        end
      end
    end
  end
end