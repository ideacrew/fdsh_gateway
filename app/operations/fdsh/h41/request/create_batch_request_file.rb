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

          batch_timestamp = fetch_batch_timestamp(values[:new_batch_reference])
          zip_name = values[:outbound_folder].to_s + "/SBE00ME.DSH.EOYIN.D#{batch_timestamp}"

          Zip::File.open(zip_name, create: true) do |zipfile|
            xml_files.each do |filename|
              zipfile.add(filename, File.join(values[:outbound_folder], filename))
            end
          end

          xml_files.each do |file_name|
            FileUtils.rm_rf(File.join(values[:outbound_folder], file_name))
          end
        end

        # Fetches the timestamp for a given batch reference.
        #
        # If the feature `:cms_eft_serverless` is enabled in `FdshGatewayRegistry`, the timestamp is formatted as:
        # YYMMDD.THHMMSSMMM.P
        # Otherwise, the timestamp is formatted as:
        # YYMMDD.THHMMSSMMM.P.IN
        #
        # @param batch_reference [String] The reference for the batch.
        # @return [String] The formatted timestamp.
        def fetch_batch_timestamp(batch_reference)
          base_format = "%y%m%d.T%H%M%S%L.P"
          format = FdshGatewayRegistry.feature_enabled?(:cms_eft_serverless) ? base_format : "#{base_format}.IN"
          DateTime.strptime(batch_reference).strftime(format)
        end
      end
    end
  end
end
