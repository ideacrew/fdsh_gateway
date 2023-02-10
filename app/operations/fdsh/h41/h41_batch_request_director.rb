# frozen_string_literal: true

module Fdsh
  module H41
    # director accepts tax_year, transactions limit per file, date time stamps
    # generates batch request zip files.
    class H41BatchRequestDirector
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      H41_EVENT_KEY = "h41_payload_requested"
      PROCESSING_BATCH_SIZE = 5000

      def call(params)
        values          = yield validate(params)
        transactions    = yield query_h41_transactions(values)
        outbound_folder = yield create_outbound_folder(values)
        outbound_folder = yield create_batch_requests(transactions, values, outbound_folder)
        batch_file      = yield create_batch_file(outbound_folder)

        Success(batch_file)
      end

      private

      def validate(params)
        return Failure('outbound folder name missing') unless params[:outbound_folder_name]
        return Failure('start date missing') unless params[:start_date]
        return Failure('end date name missing') unless params[:end_date]

        @batch_size = params[:batch_size] if params[:batch_size]

        Success(params)
      end

      def query_h41_transactions(values)
        transactions = H41Transaction.where(created_at: { :'$gte' => values[:start_date], :'$lt' => values[:end_date] })

        Success(transactions)
      end

      def processing_batch_size
        @batch_size || PROCESSING_BATCH_SIZE
      end

      def batch_request_for(offset, values)
        H41Transaction.where(created_at: { :'$gte' => values[:start_date], :'$lt' => values[:end_date] }).skip(offset).limit(processing_batch_size)
      end

      def create_outbound_folder(values)
        folder = "#{Rails.root}/#{values[:outbound_folder_name]}"
        outbound_folder = FileUtils.mkdir_p(folder).first

        Success(outbound_folder)
      end

      def open_transaction_file(_outbound_folder)
        @counter += 1
        @xml_builder = Nokogiri::XML::Builder.new do |xml|
          xml['batchreq'].Form1095ATransmissionUpstream('xmlns:air5.0' => "urn:us:gov:treasury:irs:ext:aca:air:ty20a",
                                                        'xmlns:irs' => "urn:us:gov:treasury:irs:common",
                                                        'xmlns:batchreq' => "urn:us:gov:treasury:irs:msg:form1095atransmissionupstreammessage",
                                                        'xmlns:batchresp' => "urn:us:gov:treasury:irs:msg:form1095atransmissionexchrespmessage",
                                                        'xmlns:reqack' => "urn:us:gov:treasury:irs:msg:form1095atransmissionexchackngmessage",
                                                        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance")
        end
      end

      def close_transaction_file(outbound_folder)
        xml_string = @xml_builder.to_xml(:indent => 2, :encoding => 'UTF-8')
        file_name = outbound_folder + "/EOY_Request_#{format('%05d', @counter)}_#{Time.now.gmtime.strftime('%Y%m%dT%H%M%S%LZ')}.xml"
        transaction_file = File.open(file_name, "w")
        transaction_file.write(xml_string.to_s)
        transaction_file.close
        @xml_builder = nil
      end

      def create_batch_file(outbound_folder)
        Fdsh::H41::Request::CreateBatchRequestFile.new.call({ outbound_folder: outbound_folder })
      end

      def process_for_transaction_xml(tax_household, _values, record_sequence)
        xml_string = tax_household.h41_transmission
        transaction_xml = Nokogiri.XML(xml_string, &:noblanks)
        individual_xml = transaction_xml.at("//airty20a:RecordSequenceNum")
        if (content = individual_xml.at("//airty20a:RecordSequenceNum")&.content)
          individual_xml.at("//airty20a:RecordSequenceNum").content = content + format("%05d", record_sequence)
        end

        @xml_builder.doc.at('//batchreq:Form1095ATransmissionUpstream').add_child(individual_xml)
      end

      def create_batch_requests(transactions, values, outbound_folder)
        query_offset = 0
        @counter = 0

        open_transaction_file(outbound_folder)
        while transactions.count > query_offset
          batched_requests = batch_request_for(query_offset, values)
          record_sequence = 0
          batched_requests.no_timeout.each do |transaction|
            transaction.aptc_csr_tax_households.each do |tax_household|
              record_sequence += 1

              next unless tax_household.h41_transmission.present?
              process_for_transaction_xml(tax_household, values, record_sequence)
            end
          end

          query_offset += processing_batch_size
          p "Processed #{query_offset} transactions."

          close_transaction_file(outbound_folder)
          open_transaction_file(outbound_folder)
        end

        Success(values[:outbound_folder_name])
      end
    end
  end
end

