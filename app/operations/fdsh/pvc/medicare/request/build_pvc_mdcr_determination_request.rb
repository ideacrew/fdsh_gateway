# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Pvc
    module Medicare
      module Request
        # This class takes happy mapper hash as input and returns
        class BuildPvcMdcrDeterminationRequest
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          # PublishEventStruct = Struct.new(:name, :payload, :headers)
          #
          # PUBLISH_EVENT = "on_periodic_verification_confirmation"

          # @return [Dry::Monads::Result]
          def call(applications)
            pvc_medicare_request = yield Fdsh::Pvc::Medicare::Request::TransformApplicationToPvcMedicareRequest.new.call(applications)
            xml_string = yield encode_xml_and_schema_validate(pvc_medicare_request)
            pvc_medicare_xml = yield encode_request_xml(xml_string)
            applicants_count = pvc_medicare_request.IndividualRequests.count

            Success([pvc_medicare_xml, applicants_count])
          end

          protected

          def encode_xml_and_schema_validate(esi_request)
            AcaEntities::Serializers::Xml::Fdsh::Pvc::Medicare::Operations::MedicareRequestToXml.new.call(esi_request)
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
end