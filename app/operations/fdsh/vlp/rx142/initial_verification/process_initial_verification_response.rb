# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Vlp
    module Rx142
      module InitialVerification
        # This class takes happy mapper hash as input and returns
        class ProcessInitialVerificationResponse
          include Dry::Monads[:result, :do, :try]
          include AcaEntities::AppHelper

          # @param [Hash] opts The options to process
          # @return [Dry::Monads::Result]
          def call(raw_xml)
            xml_response       = yield parse_xml_response(raw_xml.body)
            parsed_xml         = yield process_xml(xml_response)
            params             = yield construct_params(parsed_xml)
            valid_response     = yield validate_initial_response(params)
            primary_response   = yield create_primary_response(valid_response)

            Success(primary_response)
          end

          private

          def parse_xml_response(xml_string)
            parse_result = Try do
              Nokogiri::XML(xml_string)
            end
            parse_result.or do |e|
              Failure(e)
            end
            return Failure(:invalid_xml) if parse_result.success? && parse_result.value!.blank?
            parse_result
          end

          def process_xml(xml_body)
            result = AcaEntities::Serializers::Xml::Fdsh::Vlp::H92::InitialVerificationResponse.parse(xml_body, :single => true)
            Success(result)
          end

          def construct_params(parsed_xml)
            AcaEntities::Fdsh::Vlp::Rx142::InitialVerification::Operations::BuildInitialVerificationResponseParams
              .new.call(parsed_xml)
          end

          # Validate input object
          def validate_initial_response(payload)
            result = AcaEntities::Fdsh::Vlp::H92::InitialVerificationResponseContract.new.call(payload)

            if result.success?
              Success(result)
            else
              Failure("Invalid response, #{result.errors.to_h}")
            end
          end

          def create_primary_response(value)
            Success(AcaEntities::Fdsh::Vlp::H92::InitialVerificationResponse.new(value.to_h))
          end
        end
      end
    end
  end
end