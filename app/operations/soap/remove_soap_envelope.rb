# frozen_string_literal: true

module Soap
  # Extract the body from a SOAP payload.
  class RemoveSoapEnvelope
    include Dry::Monads[:result, :do, :try]

    XMLNS = { soap: "http://www.w3.org/2003/05/soap-envelope" }.freeze

    def call(xml_string)
      xml_doc = yield parse_xml_response(xml_string)
      remove_soap_envelope(xml_doc)
    end

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

    def remove_soap_envelope(soap_xml_doc)
      soap_body_element = soap_xml_doc.at_xpath("//soap:Body", XMLNS)
      child_node = soap_body_element.children.detect(&:element?)
      Success(child_node.canonicalize)
    end
  end
end
