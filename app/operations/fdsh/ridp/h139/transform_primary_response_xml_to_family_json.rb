# frozen_string_literal: true

module Fdsh
  module Ridp
    module H139
      # Take the primary response as an XML string and transform it to a JSON
      # payload representing a Family domain object.
      class TransformPrimaryResponseXmlToFamilyJson
        include Dry::Monads[:result, :do, :try]

        def call(response_xml)
          body_xml = yield strip_soap(response_xml)
          attestation = yield ProcessPrimaryResponse.new.call(body_xml)
          Success(attestation.to_json)
        end

        protected

        def strip_soap(response_xml)
          ::Soap::RemoveSoapEnvelope.new.call(response_xml)
        end
      end
    end
  end
end