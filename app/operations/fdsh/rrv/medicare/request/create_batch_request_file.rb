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

          def call(application_payloads, values)
            outbound_folder  = yield create_outbound_folder(values)
            transaction_file, applicants_count = yield create_transaction_file(application_payloads, outbound_folder)
            manifest_file    = yield create_manifest_file(transaction_file, applicants_count, outbound_folder)
            generate_batch_zip(outbound_folder, transaction_file, manifest_file)

            Success(transaction_file)
          end

          private

          def create_outbound_folder(values)
            folder = "#{Rails.root}/#{values[:outbound_folder_name]}"
            outbound_folder = FileUtils.mkdir_p(folder).first

            Success(outbound_folder)
          end

          def create_transaction_file(application_payloads, outbound_folder)
            Fdsh::Rrv::Medicare::Request::CreateTransactionFile.new.call(application_payloads, outbound_folder)
          end

          def create_manifest_file(transaction_file, applicants_count, outbound_folder)
            Fdsh::Rrv::Medicare::Request::CreateManifestFile.new.call(transaction_file, applicants_count, outbound_folder)
          end

          def generate_batch_zip(outbound_folder, transaction_file, manifest_file)
            input_files = [File.basename(transaction_file), File.basename(manifest_file)]
            @zip_name = outbound_folder + "/SBE00ME.DSH.RRVIN.D#{Time.now.strftime('%y%m%d.T%H%M%S%L.P')}.IN.zip"

            Zip::File.open(@zip_name, create: true) do |zipfile|
              input_files.each do |filename|
                zipfile.add(filename, File.join(outbound_folder, filename))
              end
            end

            FileUtils.rm_rf(File.join(outbound_folder, File.basename(transaction_file)))
            FileUtils.rm_rf(File.join(outbound_folder, File.basename(manifest_file)))
          end
        end
      end
    end
  end
end