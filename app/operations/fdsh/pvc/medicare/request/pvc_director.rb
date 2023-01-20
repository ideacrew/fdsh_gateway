# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'digest'
require 'zip'

module Fdsh
  module Pvc
    module Medicare
      module Request
        # This class creates a pvc medicare request manifest file
        class PvcDirector
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          def call(assistance_year, batch_size)
            manifest = yield find_manifest(assistance_year)
            pages = manifest.pdm_requests.count.fdiv(batch_size).ceil
            pages.times do |page|
              meta = paginator(manifest, page, assistance_year, batch_size).value!
              manifest.batch_ids << meta[:batch_id]
              manifest.file_names << meta[:file_name]
              manifest.save
            end
            manifest.generated_count = manifest.pdm_requests.count
            manifest.file_generated = true
            manifest.save
            Success("Zip(s) generated succesfully")
          end

          def paginator(manifest, page, _assistance_year, batch_size)
            request_entity = yield build_request_entity(manifest, page * batch_size, batch_size)
            medicare_payload = yield BuildPvcMdcrDeterminationRequest.new.call(request_entity)
            @medicare_file = yield create_medicare_xml_file(medicare_payload)
            manifest_request = yield construct_manifest_request
            validated_manifest_request = yield validate_manifest_request(manifest_request)
            manifest_entity = yield transform_request_to_entity(validated_manifest_request)
            xml_string = yield encode_xml_and_schema_validate(manifest_entity)
            pvc_manifest_medicare_xml = yield encode_manifest_request_xml(xml_string)
            @manifest_file = yield create_manifest_file(pvc_manifest_medicare_xml)
            zip = yield generate_batch_zip
            Success({ file_name: zip, batch_id: manifest_request[:BatchMetadata][:BatchID] })
          end

          def find_manifest(assistance_year)
            manifest = PdmManifest.where(assistance_year: assistance_year, type: "pvc_manifest_type", file_generated: false)
            return Failure("No manifest found for assistance year: #{assistance_year}, type: pvc_manifest_type") if manifest.blank?

            Success(manifest.first)
          end

          private

          def build_request_entity(manifest, skip, limit)
            request_entities = manifest.pdm_requests.skip(skip).limit(limit).each_with_object([]) do |request, collect|
              applicant_params = JSON.parse(request.request_payload)
              result = validate_applicant(applicant_params)
              return result unless result.success?
              applicant = result.value!
              next if can_skip_applicant?(applicant)
              collect << ::AcaEntities::Fdsh::Pvc::Medicare::Operations::BuildMedicareRequest.new.call(applicant, manifest.assistance_year).value!
            end
            individual_requests = { IndividualRequests: request_entities }
            result = validate_payload(individual_requests)
            return Failure("Invalid Non ESI request due to #{result.errors.to_h}") unless result.success?

            @applicants_count = request_entities.count
            esi_mec_request_entity(result.value!)
          end

          def validate_applicant(applicant_params)
            result = AcaEntities::MagiMedicaid::Contracts::ApplicantContract.new.call(applicant_params)

            if result.success?
              applicant_entity = AcaEntities::MagiMedicaid::Applicant.new(result.to_h)
              Success(applicant_entity)
            else
              Failure(result.errors)
            end
          end

          def can_skip_applicant?(applicant)
            applicant.identifying_information.encrypted_ssn.blank? || applicant.non_esi_evidence.blank?
          end

          def validate_payload(payload)
            result = AcaEntities::Fdsh::Pvc::Medicare::EesDshBatchRequestDataContract.new.call(payload)
            result.success? ? Success(result) : Failure("Invalid Non ESI request due to #{result.errors.to_h}")
          end

          def esi_mec_request_entity(payload)
            Success(AcaEntities::Fdsh::Pvc::Medicare::EesDshBatchRequestData.new(payload.to_h))
          end

          def create_medicare_xml_file(pvc_medicare_xml)
            folder = "#{Rails.root}/pvc_request_outbound"
            @outbound_folder = FileUtils.mkdir_p(folder).first
            file_name = @outbound_folder + "/MDCR_Request_00001_#{Time.now.gmtime.strftime('%Y%m%dT%H%M%S%LZ')}.xml"
            file = File.open(file_name, "w")
            file.write(pvc_medicare_xml.to_s)
            file.close
            Success(file)
          end

          def create_manifest_file(pvc_manifest_medicare_xml)
            file = File.new("#{@outbound_folder}/manifest.xml", "w")
            file.write(pvc_manifest_medicare_xml.to_s)
            file.close
            Success(file)
          end

          def validate_manifest_request(manifest_request)
            result = AcaEntities::Fdsh::Pvc::H43::BatchHandlingServiceRequestContract.new.call(manifest_request)
            result.success? ? Success(result) : Failure("Invalid Pvc Manifest request due to #{result.errors.to_h}")
          end

          def transform_request_to_entity(manifest_request)
            Success(AcaEntities::Fdsh::Pvc::H43::BatchHandlingServiceRequest.new(manifest_request.to_h))
          end

          def encode_xml_and_schema_validate(esi_request)
            AcaEntities::Serializers::Xml::Fdsh::Pvc::H43::Operations::PvcRequestToXml.new.call(esi_request)
          end

          def generate_batch_zip
            input_files = [File.basename(@medicare_file), File.basename(@manifest_file)]
            @zip_name = @outbound_folder + "/SBE00ME.DSH.PVC1.D#{Time.now.strftime('%y%m%d.T%H%M%S%L.P')}.IN"

            Zip::File.open(@zip_name, create: true) do |zipfile|
              input_files.each do |filename|
                zipfile.add(filename, File.join(@outbound_folder, filename))
              end
            end
            FileUtils.rm_rf(File.join(@outbound_folder, File.basename(@medicare_file)))
            FileUtils.rm_rf(File.join(@outbound_folder, File.basename(@manifest_file)))
            Success(@zip_name)
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

          def construct_manifest_request
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
              BatchCategoryCode: "PVC_REQ",
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
              DocumentFileName: File.basename(@medicare_file.path),
              DocumentSequenceID: "00001",
              DocumentRecordCount: @applicants_count
            }
          end

          def construct_document_binary
            {
              ChecksumAugmentation: {
                SHA256HashValueText: generate_checksum_hexdigest
              },
              BinarySizeValue: File.size(@medicare_file.path).to_s
            }
          end

          def generate_checksum_hexdigest
            sha256 = Digest::SHA256.file(@medicare_file.path)
            sha256.hexdigest
          end
        end
      end
    end
  end
end