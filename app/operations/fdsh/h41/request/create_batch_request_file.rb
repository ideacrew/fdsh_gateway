# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'zip'

module Fdsh
  module H41
    module Request
      # This class creates a batch request zip with transaction xml and manifest.
      class CreateBatchRequestFile
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        def call(params)
          values = yield validate(params)
          manifest_file = yield create_manifest_file(values)
          generate_batch_zip(values, manifest_file)

          Success(values[:outbound_folder])
        end

        private

        def validate(params)
          return Failure('outbound folder missing') unless params[:outbound_folder]
          return Failure('new_batch_reference missing') unless params[:new_batch_reference]

          Success(params)
        end

        def create_manifest_file(values)
          Fdsh::H41::Request::CreateManifestFile.new.call(values)
        end

        def generate_batch_zip(values, _manifest_file)
          xml_files = Dir.glob("#{values[:outbound_folder]}/*.xml").sort.map do |file|
            File.basename(file)
          end

          batch_timestamp = DateTime.strptime(values[:new_batch_reference]).strftime("%y%m%d.T%H%M%S%L.P.IN")
          @zip_name = values[:outbound_folder] + "/SBE00ME.DSH.EOYIN.D#{batch_timestamp}"

          Zip::File.open(@zip_name, create: true) do |zipfile|
            xml_files.each do |filename|
              zipfile.add(filename, File.join(values[:outbound_folder], filename))
            end
          end

          xml_files.each do |file_name|
            FileUtils.rm_rf(File.join(values[:outbound_folder], file_name))
          end
        end
      end
    end
  end
end
