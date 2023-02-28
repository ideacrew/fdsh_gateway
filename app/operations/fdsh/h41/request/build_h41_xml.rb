# frozen_string_literal: true

module Fdsh
  module H41
    module Request
      # BuildH41Request
      class BuildH41Xml
        include Dry::Monads[:result, :do, :try]

        DEFAULT_TRANSACTION_TYPE = :original

        def call(params)
          values      = yield validate(params)
          payload     = yield build_1095a_payload(values)
          h41_payload = yield validate_payload(payload)
          h41_request = yield h41_request_entity(h41_payload)
          xml_string  = yield encode_xml_and_schema_validate(h41_request)
          h41_xml     = yield encode_request_xml(xml_string)

          Success(h41_xml)
        end

        private

        def validate(params)
          errors = []
          errors << "family required" unless params[:family]
          errors << "agreement required" unless params[:agreement]
          errors << "insurance_policy required" unless params[:insurance_policy]
          errors << "tax_household required" unless params[:tax_household]

          if [:corrected, :void].include?(params[:transaction_type]) && !params[:record_sequence_num].is_a?(String)
            errors << 'record_sequence_num required for transaction_type'
          end

          params[:transaction_type] = DEFAULT_TRANSACTION_TYPE if params[:transaction_type].blank?

          errors.empty? ? Success(params) : Failure(errors)
        end

        def build_1095a_payload(values)
          ::Fdsh::H41::Request::Build1095aPayload.new.call(values)
        end

        def validate_payload(payload)
          result = AcaEntities::Fdsh::H41::Contracts::Form1095aUpstreamDetailContract.new.call(payload)
          result.success? ? Success(result) : Failure("Invalid H41 request due to #{result.errors.to_h}")
        end

        def h41_request_entity(payload)
          Success(AcaEntities::Fdsh::H41::Form1095aUpstreamDetail.new(payload.to_h))
        end

        def encode_xml_and_schema_validate(payload)
          xml_string = ::AcaEntities::Serializers::Xml::Fdsh::H41::Form1095ATransmissionUpstream.domain_to_mapper(payload).to_xml
          sanitized_xml = ::Fdsh::Transmissions::XmlSanitizer.new.call(xml_string: xml_string).success
          validation = AcaEntities::Serializers::Xml::Fdsh::H41::Operations::ValidateH41RequestPayloadXml.new.call(sanitized_xml)

          validation.success? ? Success(xml_string) : Failure("Invalid H41 xml due to #{validation.failure}")
        end

        def encode_request_xml(xml_string)
          encoding_result = Try do
            xml_doc = Nokogiri::XML(xml_string)
            xml_doc.to_xml(:indent => 2, :encoding => 'UTF-8')
          end

          encoding_result.or do |e|
            Failure(e)
          end
        end
      end
    end
  end
end
