# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  # Verify that the FDSH OAuth service is available
  class CheckOauthConnectivity
    include Dry::Monads[:result, :do, :try]
    include AcaEntities::AppHelper
    include EventSource::Command

    # @param [Hash] opts The options to process
    # @return [Dry::Monads::Result]
    def call(_response)
      token = yield ::Jwt::GetJwt.new.call({})
      event = yield build_event(token)
      publish(event)
    end

    CONNECTIVITY_TEST_PAYLOAD = { hubConnectivityRequest: {} }.freeze

    private

    def build_event(token)
      headers = { authorization: "Bearer #{token}", messageid: SecureRandom.uuid }
      event('events.fdsh.oauth_connectivity_checked', attributes: CONNECTIVITY_TEST_PAYLOAD, headers: headers)
    end

    def publish(event)
      Success(::Publishers::Fdsh::OauthConnectivityPublisher.publish(event))
    rescue StandardError
      Failure("failed to publish event")
    end
  end
end