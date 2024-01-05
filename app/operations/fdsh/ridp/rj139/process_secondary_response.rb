# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Ridp
    module Rj139
      # This class takes the response from CMS and returns a CV3 attestation
      class ProcessSecondaryResponse
        include Dry::Monads[:result, :do, :try]
        include AcaEntities::AppHelper

        # @param [Hash] opts The options to process
        # @return [Dry::Monads::Result]
        def call(params)
          valid_response     = yield construct_response_params(params)
          secondary_response = yield create_secondary_response(valid_response)
          ridp_attestation   = yield create_ridp_attestation(secondary_response)
          create_attestation(ridp_attestation)
        end

        private

        def construct_response_params(payload)
          AcaEntities::Fdsh::Ridp::Rj139::Operations::CmsSecondaryResponseToCv3SecondaryResponse.new.call(payload)
        end

        def create_secondary_response(value)
          result = Try do
            ::AcaEntities::Fdsh::Ridp::H139::SecondaryResponse.new(value.to_h)
          end
          result.or do
            Failure("Failed to create_secondary_response")
          end
        end

        def create_ridp_attestation(secondary_response)
          Fdsh::Ridp::H139::CreateRidpAttestation.new.call(secondary_response)
        end

        def create_attestation(ridp_attestation)
          result = Try do
            ::AcaEntities::Attestations::Attestation.new({ attestations: { ridp_attestation: ridp_attestation.to_h } })
          end
          result.or do
            Failure("Failed to create_attestation")
          end
        end
      end
    end
  end
end
