# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'zip'

module Fdsh
  module Rrv
    module Medicare
      module Request
        # This class creates a batch request zip with transaction xml and manifest.
        class CreateBatchRequestFile
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          BASE_FOLDER_NAME_FORMAT = "/SBE00ME.DSH.RRVIN.D"

          def call(params)
            values = yield validate(params)
            manifest_file = yield create_manifest_file(values)
            create_batch_zip(values, manifest_file)

            Success(values[:outbound_folder])
          end

          private

          def validate(params)
            return Failure('transaction file missing') unless params[:transaction_file]
            return Failure('applicants count missing') unless params[:applicants_count]
            return Failure('outbound folder missing') unless params[:outbound_folder]

            Success(params)
          end

          def create_manifest_file(values)
            Fdsh::Rrv::Medicare::Request::CreateManifestFile.new.call(values)
          end

          # Generates the name for the zip folder based on the current timestamp and the feature flag `:cms_eft_serverless`.
          #
          # If the feature `:cms_eft_serverless` is enabled in `FdshGatewayRegistry`, the folder name is formatted as:
          # /SBE00ME.DSH.RRVIN.DYYMMDD.THHMMSSMMM.P.zip
          # Otherwise, the folder name is formatted as:
          # /SBE00ME.DSH.RRVIN.DYYMMDD.THHMMSSMMM.P.IN.zip
          #
          # @param outbound_folder [String] The base folder where the zip file will be created.
          # @return [String] The full path of the zip file.
          def generate_zip_folder_name(outbound_folder)
            timestamp = Time.now.strftime('%y%m%d.T%H%M%S%L.P')
            extension = FdshGatewayRegistry.feature_enabled?(:cms_eft_serverless) ? "" : ".IN"
            "#{outbound_folder}#{BASE_FOLDER_NAME_FORMAT}#{timestamp}#{extension}"
          end

          def create_batch_zip(values, manifest_file)
            input_files = [File.basename(values[:transaction_file]), File.basename(manifest_file)]
            @zip_name = generate_zip_folder_name(values[:outbound_folder])

            Zip::File.open(@zip_name, create: true) do |zipfile|
              input_files.each do |filename|
                zipfile.add(filename, File.join(values[:outbound_folder], filename))
              end
            end

            FileUtils.rm_rf(File.join(values[:outbound_folder], File.basename(values[:transaction_file])))
            FileUtils.rm_rf(File.join(values[:outbound_folder], File.basename(manifest_file)))
          end
        end
      end
    end
  end
end