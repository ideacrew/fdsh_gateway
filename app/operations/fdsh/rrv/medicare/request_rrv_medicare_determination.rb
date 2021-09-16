# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Rrv
    module Medicare
      # This class takes happy mapper hash as input and returns
      class RequestRrvMedicareDetermination
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # PublishEventStruct = Struct.new(:name, :payload, :headers)
        #
        # PUBLISH_EVENT = "fdsh_determine_esi_mec_eligibility"

        # @return [Dry::Monads::Result]
        def call(application, _params)
          rrv_medicare_request = yield Fdsh::Rrv::Medicare::TransformApplicationToRrvMedicareRequest.new.call(application)
          xml_string = yield encode_xml_and_schema_validate(rrv_medicare_request)
          # TODO: STORE Request
          # _updated_transaction = yield create_or_update_transaction('request', xml_string, params)
          rrv_medicare_xml = yield encode_request_xml(xml_string)

          create_manifest_file(rrv_medicare_xml)

          Success(rrv_medicare_xml)
        end

        protected

        def encode_xml_and_schema_validate(esi_request)
          AcaEntities::Serializers::Xml::Fdsh::Rrv::Medicare::Operations::MedicareRequestToXml.new.call(esi_request)
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

        def create_manifest_file(rrv_medicare_xml)
          Fdsh::Rrv::CreateRequestManifestFile.new.call(rrv_medicare_xml: rrv_medicare_xml)
        end
      end
    end
  end
end
