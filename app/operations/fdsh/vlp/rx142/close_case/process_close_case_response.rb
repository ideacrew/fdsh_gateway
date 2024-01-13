# frozen_string_literal: true

module Fdsh
  module Vlp
    module Rx142
      module CloseCase
        # Invoke close case service for 37.1 updates
        class ProcessCloseCaseResponse
          include Dry::Monads[:result, :do, :try]
          include AcaEntities::AppHelper

          # @param [Hash] opts The options to process
          # @return [Dry::Monads::Result]
          def call(xml_response)
            parsed_xml         = yield parse_xml_response(xml_response.body)
            serialized_xml     = yield process_xml(parsed_xml)
            params             = yield build_params(serialized_xml)
            valid_response     = yield validate_close_case_response(params)
            response           = yield create_response(valid_response)

            Success(response)
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
            result = AcaEntities::Serializers::Xml::Fdsh::Vlp::Rx142::CloseCase::CloseCaseResponse.parse(xml_body, :single => true)
            Success(result)
          end

          def build_params(parsed_xml)
            params = AcaEntities::Fdsh::Vlp::Rx142::CloseCase::Operations::BuildCloseCaseResponseParams.new.call(parsed_xml)
            Success(params)
          end

          def validate_close_case_response(payload)
            result = ::AcaEntities::Fdsh::Vlp::Rx142::CloseCase::Contracts::CloseCaseResponseContract.new.call(payload)

            if result.success?
              Success(result)
            else
              Failure("Invalid response, #{result.errors.to_h}")
            end
          end

          def create_response(value)
            Success(::AcaEntities::Fdsh::Vlp::Rx142::CloseCase::CloseCaseResponse.new(value.to_h))
          end
        end
      end
    end
  end
end