# frozen_string_literal: true

module Fdsh
  module Vlp
    module Rx142
      module CloseCase
        # Invoke a Initial verification service 142.1, and, if appropriate, broadcast the response.
        class CreateCloseCaseXmlRequest
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          PublishEventStruct = Struct.new(:name, :payload, :headers, :message)

          PUBLISH_EVENT = "vlp_close_case_requested"
          # @param params [String] the json payload of the person
          # @return [Dry::Monads::Result]
          def call(params)
            close_case_request = yield validate_params(params)
            xml_payload = yield transform_params(close_case_request)
            encoded_payload = yield encode_request_xml(xml_payload)

            Success(encoded_payload)
          end

          protected

          def validate_params(params)
            ::AcaEntities::Fdsh::Vlp::Rx142::CloseCase::Operations::VerifyCloseCaseRequest.new.call(params)
          end

          def transform_params(close_case_request)
            if close_case_request.is_a?(::AcaEntities::Fdsh::Vlp::Rx142::CloseCase::CloseCaseRequest)
              ::AcaEntities::Serializers::Xml::Fdsh::Vlp::Rx142::CloseCase::Operations::CloseCaseRequestToXml.new.call(close_case_request)
            else
              Failure(
                "Invalid request, value is not a ::AcaEntities::Fdsh::Vlp::Rx142::CloseCase::CloseCaseRequest, input_value:#{close_case_request}"
              )
            end
          end

          def encode_request_xml(xml_string)
            encoding_result = Try do
              xml_doc = Nokogiri::XML(xml_string)
              xml_doc.to_xml(:indent => 2, :encoding => 'UTF-8', :save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
            end

            encoding_result.or do |e|
              Failure(e)
            end
          end
        end
      end
    end
  end
end