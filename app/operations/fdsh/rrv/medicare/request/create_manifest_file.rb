# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'digest'

module Fdsh
  module Rrv
    module Medicare
      module Request
        # This class create a rrv medicare request manifest file
        class CreateManifestFile
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          def call(params)
            values                     = yield validate(params)
            manifest_request           = yield construct_manifest_request(values)
            validated_manifest_request = yield validate_manifest_request(manifest_request)
            manifest_entity            = yield transform_request_to_entity(validated_manifest_request)
            xml_string                 = yield encode_xml_and_schema_validate(manifest_entity)
            rrv_manifest_medicare_xml  = yield encode_manifest_request_xml(xml_string)
            manifest_file              = yield create_manifest_file(rrv_manifest_medicare_xml, values[:outbound_folder])

            Success(manifest_file)
          end

          private

          def validate(params)
            return Failure('transaction file missing') unless params[:transaction_file]
            return Failure('applicants count missing') unless params[:applicants_count]
            return Failure('outbound folder missing') unless params[:outbound_folder]
    
            Success(params)
          end

          def validate_manifest_request(manifest_request)
            result = AcaEntities::Fdsh::Rrv::H79::BatchHandlingServiceRequestContract.new.call(manifest_request)
            result.success? ? Success(result) : Failure("Invalid Rrv Manifest request due to #{result.errors.to_h}")
          end

          def transform_request_to_entity(manifest_request)
            Success(AcaEntities::Fdsh::Rrv::H79::BatchHandlingServiceRequest.new(manifest_request.to_h))
          end

          def encode_xml_and_schema_validate(esi_request)
            AcaEntities::Serializers::Xml::Fdsh::Rrv::H79::Operations::RrvRequestToXml.new.call(esi_request)
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
            @transaction_file = values[:transaction_file]
            @applicants_count = values[:applicants_count]

            manifest_request = {
              BatchMetadata: construct_batch_metadata,
              TransmissionMetadata: construct_transmission_metadata,
              ServiceSpecificData: construct_service_specific_data
            }

            Success(manifest_request)
          end

          def construct_batch_metadata
            {
              BatchID: Time.now.gmtime.strftime("%Y-%m-%dT%H:%M:%SZ"),
              BatchPartnerID: "02.ME*.SBE.001.001",
              BatchAttachmentTotalQuantity: 1,
              BatchCategoryCode: "RRV_REQ",
              BatchTransmissionQuantity: 1
            }
          end

          def construct_transmission_metadata
            {
              TransmissionAttachmentQuantity: 1,
              TransmissionSequenceID: 1
            }
          end

          def construct_service_specific_data
            {
              MedicareFileMetadata: {
                MedicareDocumentAttachmentQuantity: 1,
                Attachment: construct_attachment
              }
            }
          end

          def construct_attachment
            {
              DocumentBinary: construct_document_binary,
              DocumentFileName: File.basename(@transaction_file.path),
              DocumentSequenceID: "00001",
              DocumentRecordCount: @applicants_count
            }
          end

          def construct_document_binary
            {
              ChecksumAugmentation: {
                SHA256HashValueText: generate_checksum_hexdigest
              },
              BinarySizeValue: File.size(@transaction_file.path).to_s
            }
          end

          def generate_checksum_hexdigest
            sha256 = Digest::SHA256.file(@transaction_file.path)
            sha256.hexdigest
          end

          def create_manifest_file(rrv_manifest_medicare_xml, outbound_folder)
            file = File.new("#{outbound_folder}/manifest.xml", "w")
            file.write(rrv_manifest_medicare_xml.to_s)
            file.close

            Success(file)
          end
        end
      end
    end
  end
end
