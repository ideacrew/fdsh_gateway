# frozen_string_literal: true

module Fdsh
  module Ssa
    module H3
      # This class takes a json representing a person as input and invokes SSA.
      class RequestSsaVerification
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        PublishEventStruct = Struct.new(:name, :payload, :headers)

        PUBLISH_EVENT = "ssa_verification_requested"

        # @param params [String] the json payload of the person
        # @return [Dry::Monads::Result]
        def call(params)
          json_hash = yield parse_json(params)
          person_hash = yield validate_person_json_hash(json_hash)
          person = yield build_person(person_hash)
          ssa_verification_request = yield TransformPersonToSsaRequest.new.call(person)
          xml_string = yield encode_xml_and_schema_validate(ssa_verification_request)
          ssa_verification_request_xml = yield encode_request_xml(xml_string)

          publish_event(ssa_verification_request_xml)
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

        def encode_xml_and_schema_validate(ssa_verification_request)
          AcaEntities::Serializers::Xml::Fdsh::Ssa::H3::Operations::SsaRequestToXml.new.call(ssa_verification_request)
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

        def publish_event(ssa_verification_request_xml)
          event = PublishEventStruct.new(PUBLISH_EVENT, ssa_verification_request_xml)
          Success(Publishers::Fdsh::SsaServicePublisher.publish(event))
        end
      end
    end
  end
end