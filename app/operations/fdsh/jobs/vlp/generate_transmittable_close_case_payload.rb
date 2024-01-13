# frozen_string_literal: true

module Fdsh
  module Jobs
    module Vlp
      # create job operation that takes params of key (required), started_at(required), publish_on(required), payload (required)
      class GenerateTransmittableCloseCasePayload < GenerateTransmittableVlpPayload
        def validate_params(params)
          return Failure('Transmittable payload cannot be created without a case_number a string') unless params[:case_number].is_a?(String)
          super
        end

        def generate_transmittable_payload(values)
          close_case_payload = { CaseNumber: values[:case_number] }
          @transformed_payload = ::Fdsh::Vlp::Rx142::CloseCase::CreateCloseCaseXmlRequest.new.call(close_case_payload)
          super
        end
      end
    end
  end
end