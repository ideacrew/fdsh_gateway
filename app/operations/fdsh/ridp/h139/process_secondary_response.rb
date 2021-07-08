# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Ridp
    module H139
      # This class takes happy mapper hash as input and returns
      class ProcessSecondaryResponse
        include Dry::Monads[:result, :do, :try]
        include AcaEntities::AppHelper

        # @param [Hash] opts The options to process
        # @return [Dry::Monads::Result]
        def call(xml_response)
          parsed_xml         = yield process_xml(xml_response)
          params             = yield construct_params(parsed_xml)
          valid_response     = yield validate_secondary_response(params)
          secondary_response = yield create_secondary_response(valid_response)
          ridp_attestation   = yield create_ridp_attestation(secondary_response)
          attestation        = yield create_attestation(ridp_attestation)

          Success(attestation)
        end

        private

        def process_xml(xml_response)
          result = AcaEntities::Serializers::Xml::Fdsh::Ridp::SecondaryResponse.parse(xml_response.root.canonicalize, :single => true)
          Success(result)
        end

        def construct_params(parsed_xml)
          result_hash = {
            Response: {
              ResponseMetadata: {
                ResponseCode: parsed_xml.response_metadata.ResponseCode,
                ResponseDescriptionText: parsed_xml.response_metadata.ResponseDescriptionText,
                TDSResponseDescriptionText: parsed_xml.response_metadata.TDSResponseDescriptionText
              },

              VerificationResponse: {
                SessionIdentification: parsed_xml.verification_response.SessionIdentification,
                DSHReferenceNumber: parsed_xml.verification_response.DSHReferenceNumber,
                FinalDecisionCode: parsed_xml.verification_response.FinalDecisionCode
              }
            }
          }

          Success(result_hash)
        end

        # Validate input object
        def validate_secondary_response(payload)
          result = ::AcaEntities::Fdsh::Ridp::H139::SecondaryResponseContract.new.call(payload)

          if result.success?
            Success(result)
          else
            Failure("Invalid response, #{result.errors}")
          end
        end

        def create_secondary_response(value)
          Success(::AcaEntities::Fdsh::Ridp::H139::SecondaryResponse.new(value.to_h))
        end

        def create_ridp_attestation(secondary_response)
          Fdsh::Ridp::H139::CreateRidpAttestation.new.call(secondary_response)
        end

        def create_attestation(ridp_attestation)
          Success(::AcaEntities::Attestations::Attestation.new({ attestations: ridp_attestation.to_h }))
        end
      end
    end
  end
end
