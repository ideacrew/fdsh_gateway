# frozen_string_literal: true

module Fdsh
  module Ridp
    module H139
      # This class takes a json representing a family as input and invokes RIDP
      # for the secondary determination.
      class RequestSecondaryDetermination
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        PublishEventStruct = Struct.new(:name, :payload, :headers, :message)

        PUBLISH_EVENT = "fdsh_secondary_determination_requested"

        # @param params [String] the json payload of the family
        # @return [Dry::Monads::Result]
        def call(params)
          json_hash = yield parse_json(params)
          family_hash = yield validate_family_json_hash(json_hash)
          family = yield build_family(family_hash)
          determination_request = yield TransformFamilyToSecondaryDetermination.new.call(family)
          xml_string = yield encode_xml_and_schema_validate(determination_request)
          determination_request_xml = yield encode_request_xml(xml_string)

          publish_event(determination_request_xml)
        end

        protected

        def parse_json(json_string)
          parsing_result = Try do
            JSON.parse(json_string, :symbolize_names => true)
          end
          parsing_result.or do
            Failure(:invalid_json)
          end
        end

        def encode_xml_and_schema_validate(determination_request)
          AcaEntities::Serializers::Xml::Fdsh::Ridp::Operations::SecondaryRequestToXml.new.call(
            determination_request
          )
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

        def validate_family_json_hash(json_hash)
          validation_result = AcaEntities::Contracts::Families::FamilyContract.new.call(json_hash)

          validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
        end

        def build_family(family_hash)
          creation_result = Try do
            AcaEntities::Families::Family.new(family_hash)
          end

          creation_result.or do |e|
            Failure(e)
          end
        end

        # Re-enable once soap is fixed.
        def publish_event(determination_request_xml)
          event = PublishEventStruct.new(PUBLISH_EVENT, determination_request_xml)

          Success(Publishers::Fdsh::RidpServicePublisher.publish(event))
        end

      end
    end
  end
end