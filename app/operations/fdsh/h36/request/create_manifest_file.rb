# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'digest'

module Fdsh
  module H36
    module Request
      # This class create a H41 request manifest file
      class CreateManifestFile
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        def call(params)
          values                     = yield validate(params)
          manifest_request           = yield construct_manifest_request(values)
          validated_manifest_request = yield validate_manifest_request(manifest_request)
          manifest_entity            = yield transform_request_to_entity(validated_manifest_request)
          xml_string                 = yield encode_xml_and_schema_validate(manifest_entity)
          manifest_h36_xml           = yield encode_manifest_request_xml(xml_string)
          manifest_file              = yield create_manifest_file(manifest_h36_xml, values[:outbound_folder])

          Success(manifest_file)
        end

        private

        def validate(params)
          return Failure('outbound folder missing') unless params[:outbound_folder]
          return Failure('outbound folder missing') unless params[:transmission_kind]
          return Failure('max month missing') unless params[:max_month]
          return Failure('calendar year missing') unless params[:calendar_year]

          Success(params)
        end

        def validate_manifest_request(manifest_request)
          result = AcaEntities::Fdsh::H36::Contracts::BatchHandlingServiceRequestContract.new.call(manifest_request)
          result.success? ? Success(result) : Failure("Invalid H41 Manifest request due to #{result.errors.to_h}")
        end

        def transform_request_to_entity(manifest_request)
          Success(AcaEntities::Fdsh::H36::BatchHandlingServiceRequest.new(manifest_request.to_h))
        end

        def encode_xml_and_schema_validate(request)
          AcaEntities::Serializers::Xml::Fdsh::H36::Operations::CreateH36ManifestXml.new.call(request)
        end

        def encode_manifest_request_xml(xml_string)
          encoding_result = Try do
            xml_doc = Nokogiri::XML(xml_string)
            xml_doc.to_xml(:indent => 2, :encoding => 'UTF-8')
          end

          encoding_result.or do |e|
            Failure(e)
          end
        end

        def construct_manifest_request(values)
          @attachment_files = Dir.glob("#{values[:outbound_folder]}/*.xml").sort

          manifest_request = {
            BatchMetadata: construct_batch_metadata(values),
            TransmissionMetadata: construct_transmission_metadata,
            ServiceSpecificData: construct_service_specific_data(values),
            Attachments: construct_attachments
          }

          Success(manifest_request)
        end

        def construct_batch_metadata(values)
          {
            BatchID: values[:batch_reference] || Time.now.gmtime.strftime("%Y-%m-%dT%H:%M:%SZ"),
            BatchPartnerID: "02.ME*.SBE.001.001",
            BatchAttachmentTotalQuantity: @attachment_files.count,
            BatchCategoryCode: "IRS_EOM_REQ",
            BatchTransmissionQuantity: 1
          }
        end

        def construct_transmission_metadata
          {
            TransmissionAttachmentQuantity: @attachment_files.count,
            TransmissionSequenceID: 1
          }
        end

        def construct_service_specific_data(values)
          {
            ReportPeriod: { YearMonth: fetch_report_period(values) }
          }
        end

        def fetch_report_period(values)
          report_period = Date.today.prev_month.strftime("%Y-%m")
          if values[:calendar_year] == Date.today.prev_year.year && values[:max_month] > 12
            report_period = Date.new(values[:calendar_year], 12, 1).strftime("%Y-%m")
          end
          report_period
        end

        def construct_attachments
          @attachment_files.each_with_index.map do |file_path, i|
            file = File.open(file_path)
            {
              DocumentBinary: construct_document_binary(file),
              DocumentFileName: File.basename(file_path),
              DocumentSequenceID: format("%05d", (i + 1))
            }
          end
        end

        def construct_document_binary(file)
          {
            ChecksumAugmentation: {
              SHA256HashValueText: generate_checksum_hexdigest(file)
            },
            BinarySizeValue: File.size(file.path).to_s
          }
        end

        def generate_checksum_hexdigest(file)
          sha256 = Digest::SHA256.file(file.path)
          sha256.hexdigest
        end

        def create_manifest_file(manifest_h36_xml, outbound_folder)
          file = File.new("#{outbound_folder}/manifest.xml", "w")
          file.write(manifest_h36_xml.to_s)
          file.close

          Success(file)
        end
      end
    end
  end
end
