# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Ridp
    module H139
      # This class takes happy mapper hash as input and returns
      class CheckConnectivity
        include Dry::Monads[:result, :do, :try]
        include AcaEntities::AppHelper

        PublishEventStruct = Struct.new(:name, :payload, :headers)

        PUBLISH_EVENT = "fdsh_connectivity_check_requested"

        # @param [Hash] opts The options to process
        # @return [Dry::Monads::Result]
        def call(_response)
          publish
        end

        CONNECTIVITY_TEST_PAYLOAD = <<-XMLCODE
          <hubc:HubConnectivityRequest xmlns:hubc="http://hubc.ee.sim.dsh.cms.hhs.gov" xmlns:soap="http://www.w3.org/2003/05/soap-envelope">ME</hubc:HubConnectivityRequest>
        XMLCODE

        private

        def publish
          event = PublishEventStruct.new(PUBLISH_EVENT, CONNECTIVITY_TEST_PAYLOAD)
          Success(::Publishers::Fdsh::RidpConnectivityPublisher.publish(event))
        end
      end
    end
  end
end
