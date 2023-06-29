# frozen_string_literal: true

module Fdsh
  module Ssa
    module H3
      # This class takes a json representing a person as input and invokes SSA.
      class RequestJsonSsaVerification
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        PublishEventStruct = Struct.new(:name, :payload, :headers)

        PUBLISH_EVENT = "ssa_verification_requested"

        # @param params [String] the json payload of the person
        # @return [Dry::Monads::Result]
        def call(_params)
          # Get payload that is ready to transmitted
          xml_string = yield encode_xml_and_schema_validate(ssa_verification_request)
          ssa_verification_request_xml = yield encode_request_xml(xml_string)

          publish_event(ssa_verification_request_xml)
        end

        protected

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

        def publish_event(ssa_verification_request_xml)
          event = PublishEventStruct.new(PUBLISH_EVENT, ssa_verification_request_xml)
          Success(Publishers::Fdsh::SsaServicePublisher.publish(event))
        end
      end
    end
  end
end