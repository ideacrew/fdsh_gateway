# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'digest'
require 'zip'

module Fdsh
  module Pvc
    module Medicare
      module Response
        # This class create a pvc medicare response manifest file
        class ParsePvcMedicareResponse
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          def call(file_path)
            unzip_medicare_response(file_path)
            processed_manifest_xml = yield parse_manifest_response_xml
            processed_medicare_xml = yield parse_medicare_response_xml
            _status = yield verify_checksum(processed_manifest_xml)
            response_entity = yield ConstructMedicareResponse.new.call(processed_medicare_xml)
            process_pvc_ifsv_determination(response_entity)
            Success(response_entity)
          end

          private

          def process_pvc_ifsv_determination(response_entity)
            ProcessPvcMedicareDetermination.new.call(response_entity) if response_entity.IndividualResponses.present?
          end

          def unzip_medicare_response(file_path)
            # file-path: "{Rails.root}/pvc_medicare_response.zip"
            path = File.join(file_path)
            Zip::File.open(path) do |zip_file|
              zip_file.each do |f|
                f_path = File.join("#{Rails.root}/", f.name)
                FileUtils.mkdir_p(File.dirname(f_path))
                zip_file.extract(f, f_path) unless File.exist?(f_path)
              end
            end
          end

          def parse_manifest_response_xml
            manifest_response_xml = File.read("#{Rails.root}/manifest.xml")
            valid_xml = remove_xml_node(manifest_response_xml)
            Success(AcaEntities::Serializers::Xml::Fdsh::Pvc::H43::Response::BatchHandlingServiceResponse.parse(valid_xml, :single => true))
          end

          def parse_medicare_response_xml
            file_name = Dir.glob('MDCR_Response_*.xml').first
            pvc_response_xml = File.read(file_name)
            valid_xml = remove_xml_node(pvc_response_xml)
            Success(AcaEntities::Serializers::Xml::Fdsh::Pvc::Medicare::EesDshBatchResponseData.parse(valid_xml, :single => true))
          end

          def remove_xml_node(response_xml)
            xml_doc =  Nokogiri::XML(response_xml)
            child_node = xml_doc.children.detect(&:element?)
            child_node.canonicalize
          end

          def verify_checksum(manifest_xml)
            checksum = manifest_xml.Attachments.first.DocumentBinary.ChecksumAugmentation
            file_name = Dir.glob('MDCR_Response_*.xml').first
            pvc_response_xml_checksum = generate_checksum_hexdigest(File.join(file_name))
            checksum.SHA256HashValueText == pvc_response_xml_checksum ? Success(true) : Failure("Checksum did not match")
          end

          def generate_checksum_hexdigest(file_path)
            sha256 = Digest::SHA256.file(file_path)
            sha256.hexdigest
          end

          def remove_unziped_dir
            FileUtils.rm_rf("#{Rails.root}/pvc_medicare_response")
          end
        end
      end
    end
  end
end
