# frozen_string_literal: true

module Fdsh
  module Ridp
    module Rj139
      # This class takes a json representing a person as input and invokes RIDP primary request.
      class RequestRidpPrimaryVerification
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        PublishEventStruct = Struct.new(:name, :payload, :headers)

        PUBLISH_EVENT = "ridp_primary_verification_request_rest"
        # @param params [String] the json payload of the person
        # @return [Dry::Monads::Result]
        def call(params)
          validated_params = yield validate_params(params)
          publish_event(validated_params)
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

        def publish_event(params)
          event = PublishEventStruct.new(PUBLISH_EVENT, params[:transmittable_objects][:transaction].json_payload,
                                         { authorization: "Bearer #{params[:token]}",
                                           messageid: params[:transmittable_objects][:job].message_id,
                                           partnerid: ENV.fetch('CMS_PARTNER_ID', nil) })
          result = update_status(params[:transmittable_objects])
          return Failure("Could not publish payload #{result.failure}") if result.failure?

          Success(::Publishers::Fdsh::RidpPrimaryRequestRestPublisher.publish(event))
        end

        def update_status(transmittable_hash)
          Fdsh::Jobs::UpdateProcessStatus.new.call({ transmittable_objects: transmittable_hash, state: :transmitted,
                                                     message: "transmitted to cms" })
        end
      end
    end
  end
end