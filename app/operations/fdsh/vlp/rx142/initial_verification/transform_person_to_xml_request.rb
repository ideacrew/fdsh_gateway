# frozen_string_literal: true

module Fdsh
  module Vlp
    module Rx142
      module InitialVerification
        # This class takes a json representing a person as input and returns an excoded XML.
        class TransformPersonToXmlRequest
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          # @param params [String] the json payload of the person
          # @return [Dry::Monads::Result]
          def call(params)
            json_hash = yield parse_json(params)
            person_hash = yield validate_person_json_hash(json_hash)
            person = yield build_person(person_hash)
            initial_verification_request = yield Fdsh::Vlp::Rx142::InitialVerification::TransformPersonToInitialRequest.new.call(person)
            xml_string = yield encode_xml_and_schema_validate(initial_verification_request)
            encode_request_xml(xml_string)
          end

          protected

          def parse_json(json_string)
            parsing_result = Try do
              JSON.parse(json_string, :symbolize_names => true)
            end
            parsing_result.or do
              Failure("Failed to parse JSON for VLP request due to #{e}")
            end
          end

          def encode_xml_and_schema_validate(initial_verification_request)
            AcaEntities::Serializers::Xml::Fdsh::Vlp::H92::Operations::InitialRequestToXml.new.call(initial_verification_request)
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

          def validate_person_json_hash(json_hash)
            validation_result = AcaEntities::Contracts::People::PersonContract.new.call(json_hash)

            validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
          end

          def build_person(person_hash)
            creation_result = Try do
              AcaEntities::People::Person.new(person_hash)
            end

            creation_result.or do |e|
              Failure(e)
            end
          end
        end
      end
    end
  end
end