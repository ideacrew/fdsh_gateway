# frozen_string_literal: true

module Fdsh
  module H41
    module Request
      # This class takes an family payload hash as input and returns transaction xml and policy count.
      class CreateTransactionFile
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          def call(params)
            binding.irb
            values               = yield validate(params)
            families             = yield build_families(values)
            h41_request          = yield build_request_entity(families)
            xml_string           = yield encode_xml_and_schema_validate(h41_request)
            h41_xml             =   yield encode_request_xml(xml_string)
            policies_count     = h41_request.Form1095AUpstreamDetail.count

            Success([h41_xml, policies_count])
          end

          private

          def validate(params)
            return Failure('family payload is missing') unless params[:family_payload]
            Success(params)
          end

          def build_families(values)
            family = values[:family_payload].collect do |family_hash|
              AcaEntities::Families::Family.new(family_hash)
            end.compact

            Success(family)
          end

          # Transform family params To BuildH41Request Contract params
          def build_request_entity(families)
            ::AcaEntities::Fdsh::H41::Operations::BuildH41Request.new.call(families)
          end

          def encode_xml_and_schema_validate(h41_request)
            xml_string = ::AcaEntities::Serializers::Xml::Fdsh::H41::Form1095ATransmissionUpstream.domain_to_mapper(h41_request).to_xml
            Success(xml_string)
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
