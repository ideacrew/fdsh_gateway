# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Ridp
    module Rj139
      # This class takes the response from CMS and returns a CV3 attestation
      class ProcessPrimaryResponse
        include Dry::Monads[:result, :do, :try]
        include AcaEntities::AppHelper

        # @param [Hash] opts The options to process
        # @return [Dry::Monads::Result]
        def call(params)
          valid_response     = yield construct_response_params(params)
          primary_response   = yield create_primary_response(valid_response)
          ridp_attestation   = yield create_ridp_attestation(primary_response)
          attestation        = yield create_attestation(ridp_attestation)

          Success(attestation)
        end

        private

        def construct_response_params(payload)
          AcaEntities::Fdsh::Ridp::Rj139::Operations::CmsPrimaryResponseToCv3PrimaryResponse.new.call(payload)
        end

        def create_primary_response(value)
          result = Try do
            ::AcaEntities::Fdsh::Ridp::H139::PrimaryResponse.new(value.to_h)
          end
          result.or do
            Failure("Failed to create_primary_response")
          end
        end

        def create_ridp_attestation(primary_response)
          Fdsh::Ridp::H139::CreateRidpAttestation.new.call(primary_response)
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
