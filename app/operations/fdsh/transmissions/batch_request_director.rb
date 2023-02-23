# frozen_string_literal: true

module Fdsh
  module Transmissions
    # director accepts tax_year, transactions limit per file, date time stamps
    # generates batch request zip files.
    class BatchRequestDirector
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      attr_reader :transmission_builder

      H41_EVENT_KEY = "h41_payload_requested"
      PROCESSING_BATCH_SIZE = 5000

      def call(params)
        values = yield validate(params)
        values = yield create_transmission_variables(values)
        outbound_folder     = yield create_outbound_folder(values)
        outbound_folder     = yield create_batch_content_files(values, outbound_folder)
        output              = yield create_batch_request_file(outbound_folder)

        Success(output)
      end

      private

      def validate(params)
        # binding.irb
        return Failure('transactions collection required') unless params[:transactions]
        return Failure('outbound folder name missing') unless params[:outbound_folder_name]
        return Failure('transmission_builder missing') unless params[:transmission_builder]
        return Failure('transmission_kind missing') unless params[:transmission_kind]

        Success(params)
      end

      def create_transmission_variables(values)
        @transmission_builder = values[:transmission_builder]
        @batch_size = values[:batch_size] if values[:batch_size]

        Success(values)
      end

      def batched_request_for(transactions, offset)
        transactions.skip(offset).limit(processing_batch_size).no_timeout if transactions.is_a?(Mongoid::Criteria)
      end

      def create_batch_content_files(values, outbound_folder)
        query_offset = 0
        @counter = 0

        while values[:transactions].count > query_offset
          open_content_file
          batched_requests = batched_request_for(values[:transactions], query_offset)
          record_sequence = 0

          batched_requests.each do |transaction|
            record_sequence += 1
            subject = transaction.transactable
            transaction_xml = Nokogiri.XML(subject.transaction_xml, &:noblanks)
            transmission_builder.append_xml(transaction, transaction_xml, record_sequence)
          end

          query_offset += processing_batch_size
          p "Processed #{query_offset} transactions."

          close_content_file(outbound_folder)
        end

        Success(outbound_folder)
      end

      def processing_batch_size
        @batch_size || PROCESSING_BATCH_SIZE
      end

      def open_content_file
        @counter += 1
        transmission_builder.new_document(@counter)
      end

      def create_batch_request_file(outbound_folder)
        transmission_builder.build_manifest_and_transmission(outbound_folder)
      end

      def create_outbound_folder(values)
        folder = "#{Rails.root}/#{values[:outbound_folder_name]}"
        Success(FileUtils.mkdir_p(folder).first)
      end

      def close_content_file(outbound_folder)
        xml_string = transmission_builder.document.to_xml(:indent => 2, :encoding => 'UTF-8')
        file_name = outbound_folder + transmission_builder.filename
        transaction_file = File.open(file_name, "w")
        transaction_file.write(xml_string.to_s)
        transaction_file.close
        transmission_builder.document = nil
      end
    end
  end
end

