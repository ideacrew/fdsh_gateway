# frozen_string_literal: true

module Fdsh
  module Jobs
    module Vlp
      # create job operation that takes params of key (required), started_at(required), publish_on(required), payload (required)
      class GenerateTransmittableInitialVerificationPayload < GenerateTransmittableVlpPayload
        include Dry::Monads[:result, :do, :try]

        def generate_transmittable_payload(payload)
          @result = Fdsh::Vlp::Rx142::InitialVerification::TransformPersonToXmlRequest.new.call(payload)
          super
        end
      end
    end
  end
end