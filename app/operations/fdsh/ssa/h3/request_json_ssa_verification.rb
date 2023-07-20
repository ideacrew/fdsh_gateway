# frozen_string_literal: true

module Fdsh
  module Ssa
    module H3
      # This class takes a json representing a person as input and invokes SSA.
      class RequestJsonSsaVerification
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        PublishEventStruct = Struct.new(:name, :payload, :headers)

        PUBLISH_EVENT = "verify_ssa_composite_service_rest_request"
        # @param params [String] the json payload of the person
        # @return [Dry::Monads::Result]
        def call(params)
          validated_params = yield validate_params(params)
          publish_event(validated_params)
        end

        protected

        def validate_params(params)
          return Failure('Cannot publish payload without transaction') unless params[:values][:transaction].is_a?(::Transmittable::Transaction)
          return Failure('Cannot publish payload without correlation_id') unless params[:correlation_id].is_a?(String)
          return Failure('Cannot publish payload without jwt token') unless params[:token].is_a?(String)
          return Failure('Cannot publish payload without transaction json payload') unless params[:values][:transaction].json_payload

          Success(params)
        end

        def publish_event(params)
          event = PublishEventStruct.new(PUBLISH_EVENT, params[:values][:transaction].json_payload, { authorization: "Bearer #{params[:token]}",
                                                                                                      messageid: params[:values][:message_id],
                                                                                                      partnerid: ENV['CMS_PARTNER_ID'] })

          Success(::Publishers::Fdsh::VerifySsaCompositeServiceRestPublisher.publish(event))
        end
      end
    end
  end
end