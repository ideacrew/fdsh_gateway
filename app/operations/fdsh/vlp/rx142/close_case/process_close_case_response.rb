# frozen_string_literal: true

module Fdsh
  module Vlp
    module Rx142
      module CloseCase
        # Invoke a Initial verification service 142.1, and, if appropriate, broadcast the response.
        class ProcessCloseCaseResponse
          include Dry::Monads[:result, :do, :try]
          include AcaEntities::AppHelper

          XMLNS = {
            soap: "http://www.w3.org/2003/05/soap-envelope"
          }.freeze

          # @param [Hash] opts The options to process
          # @return [Dry::Monads::Result]
          def call(xml_response)
            parsed_xml         = yield process_xml(xml_response)
            # TODO: we should move all the construction into aca_entities rather than having it in FDSH
            params             = yield construct_params(parsed_xml)
            # TODO: we should move all the validation into aca_entities rather than having it in FDSH
            valid_response     = yield validate_close_case_response(params)
            primary_response   = yield create_primary_response(valid_response)

            Success(primary_response)
          end

          private

          def process_xml(xml_body)
            # TODO: switch this out for the new operation when ready
            result = AcaEntities::Serializers::Xml::Fdsh::Vlp::Rx142::CloseCase::CloseCaseResponse.parse(xml_body, :single => true)
            Success(result)
          end

          # we should move all the construction into aca_entities rather than having it in FDSH
          def construct_params(parsed_xml)
            result_hash = {
              ResponseMetadata: construct_response_metadata(parsed_xml&.ResponseMetadata),
              ArrayOfErrorResponseMetadata: construct_array_error_response_metadata(parsed_xml&.ArrayOfErrorResponseMetadata),
              CloseCaseResponseSet: get_close_case_response_set(parsed_xml&.CloseCaseResponseSet)
            }

            Success(result_hash)
          end

          def get_close_case_response_set(close_case_response)
            return nil unless close_case_response

            { WebServSftwrVer: close_case_response&.WebServSftwrVer }
          end

          def construct_array_error_response_metadata(error_data_array)
            return nil unless error_data_array

            error_metadata_array.ErrorData.collect do |error_data|
              {
                ErrorResponseCode: error_data&.ErrorResponseCode,
                ErrorResponseDescriptionText: error_data&.ErrorResponseDescriptionText,
                ErrorTDSResponseDescriptionText: error_data&.ErrorTDSResponseDescriptionText
              }
            end
          end

          def construct_response_metadata(metadata)
            {
              ResponseCode: metadata&.ResponseCode,
              ResponseDescriptionText: metadata&.ResponseDescriptionText,
              TDSResponseDescriptionText: metadata&.TDSResponseDescriptionText
            }
          end

          def construct_error_response_metadata(error_metadata_array)
            return nil unless error_metadata_array

            error_metadata_array.ErrorResponseMetadatas.collect do |error_metadata|
              {
                ErrorResponseCode: error_metadata&.ErrorResponseCode,
                ErrorResponseDescriptionText: error_metadata&.ErrorResponseDescriptionText,
                ErrorTDSResponseDescriptionText: error_metadata&.ErrorTDSResponseDescriptionText
              }
            end
          end

          # Validate input object
          def validate_close_case_response(payload)
            # TODO: switch this out to use the new operation when ready
            result = ::AcaEntities::Fdsh::Vlp::Rx142::CloseCase::Contracts::CloseCaseResponseContract.new.call(payload)

            if result.success?
              Success(result)
            else
              Failure("Invalid response, #{result.errors.to_h}")
            end
          end

          def create_primary_response(value)
            # TODO: switch this out to use the new operation when ready
            Success(::AcaEntities::Fdsh::Vlp::Rx142::CloseCase::CloseCaseResponse.new(value.to_h))
          end
        end
      end
    end
  end
end