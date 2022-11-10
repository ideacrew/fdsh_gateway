# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'zip'

module Fdsh
  module Rrv
    module Medicare
      module Request
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
            return Failure('transaction file missing') unless params[:transaction_file]
            return Failure('applicants count missing') unless params[:applicants_count]
            return Failure('outbound folder missing') unless params[:outbound_folder]
    
            Success(params)
          end

          def create_manifest_file(values)
            Fdsh::Rrv::Medicare::Request::CreateManifestFile.new.call(values)
          end

          def generate_batch_zip(values, manifest_file)
            input_files = [File.basename(values[:transaction_file]), File.basename(manifest_file)]
            @zip_name = values[:outbound_folder] + "/SBE00ME.DSH.RRVIN.D#{Time.now.strftime('%y%m%d.T%H%M%S%L.P')}.IN.zip"

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