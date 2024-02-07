# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  # Verify that the FDSH OAuth service is available
  class CheckOauthConnectivity
    include Dry::Monads[:result, :do, :try]
    include AcaEntities::AppHelper

    PublishEventStruct = Struct.new(:name, :payload, :headers, :message)

    PUBLISH_EVENT = "fdsh_oauth_connectivity_check_requested"

    # @param [Hash] opts The options to process
    # @return [Dry::Monads::Result]
    def call(_response)
      token = yield ::Jwt::GetJwt.new.call({})
      publish(token)
    end

    CONNECTIVITY_TEST_PAYLOAD = { hubConnectivityRequest: {} }.to_json

    private

    def publish(token)
      event = PublishEventStruct.new(PUBLISH_EVENT, CONNECTIVITY_TEST_PAYLOAD, { authorization: "Bearer #{token}", messageid: SecureRandom.uuid })
      Success(::Publishers::Fdsh::OauthConnectivityPublisher.publish(event))
    end
  end
end