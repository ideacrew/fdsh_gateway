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

        PublishEventStruct = Struct.new(:name, :payload)

        PUBLISH_EVENT = "fdsh_connectivity_check_requested"

        # @param [Hash] opts The options to process
        # @return [Dry::Monads::Result]
        def call(_response)
          publish
        end

        private

        def publish
          event = PublishEventStruct.new(PUBLISH_EVENT, "")
          Success(::Publishers::Fdsh::RidpConnectivityPublisher.publish(event))
        end
      end
    end
  end
end
