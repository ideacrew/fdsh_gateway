# frozen_string_literal: true

module Fdsh
  module Jobs
    module Vlp
      # create job operation that takes params of key (required), started_at(required), publish_on(required), payload (required)
      class GenerateTransmittableInitialVerificationPayload < GenerateTransmittableVlpPayload

        def generate_transmittable_payload(values)
          @transformed_payload = Fdsh::Vlp::Rx142::InitialVerification::TransformPersonToXmlRequest.new.call(values[:payload])
          super
        end
      end
    end
  end
end