# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      # Operation to publish an open transmission of given kind
      class H41BatchBuilder
        PROCESSING_BATCH_SIZE = 5000

        attr_reader :transactions, :new_batch_reference, :old_batch_reference, :report_type, :outbound_folder_name

        def initialize(params)
          @transactions = params[:transactions]
          @old_batch_reference = params[:old_batch_reference]
          @report_type = params[:report_type]
          @outbound_folder_name = params[:outbound_folder_name] || 'h41_transmissions'
          @new_batch_reference = create_new_batch_reference
        end

        def create_new_batch_reference
          (Time.now + 1.hour).gmtime.strftime("%Y-%m-%dT%H:%M:%SZ")
        end

        def batched_request_for(offset)
          transactions.skip(offset).limit(processing_batch_size).no_timeout if transactions.is_a?(Mongoid::Criteria)
        end

        def each
          query_offset = 0
          @counter = 0
          outbound_folder = create_outbound_folder

          open_content_file

          while transactions.count > query_offset
            batched_requests = batched_request_for(query_offset)
            record_sequence = 0

            batched_requests.each do |transaction|
              record_sequence += 1
              record_sequence_number = process_for_transaction_xml(transaction.transactable, record_sequence)
              yield(transaction, {
                batch_reference: new_batch_reference,
                record_sequence_number: record_sequence_number,
                content_file_id: format('%05d', @counter).to_s
              })
            end

            query_offset += processing_batch_size
            p "Processed #{query_offset} transactions."

            close_content_file(outbound_folder)
            open_content_file
          end
          create_batch_request_file(outbound_folder)

          outbound_folder
        end

        def processing_batch_size
          @batch_size || PROCESSING_BATCH_SIZE
        end

        def create_batch_request_file(outbound_folder)
          Fdsh::H41::Request::CreateBatchRequestFile.new.call(
            outbound_folder: outbound_folder,
            new_batch_reference: new_batch_reference,
            old_batch_reference: old_batch_reference
          )
        end

        def create_outbound_folder
          folder = "#{Rails.root}/#{outbound_folder_name}"
          FileUtils.mkdir_p(folder).first
        end

        def open_content_file
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

        def close_content_file(outbound_folder)
          xml_string = @xml_builder.to_xml(:indent => 2, :encoding => 'UTF-8')
          file_name = outbound_folder + "/EOY_Request_#{format('%05d', @counter)}_#{Time.now.gmtime.strftime('%Y%m%dT%H%M%S%LZ')}.xml"
          transaction_file = File.open(file_name, "w")
          transaction_file.write(xml_string.to_s)
          transaction_file.close
          @xml_builder = nil
        end

        def process_for_transaction_xml(tax_household, record_sequence)
          transaction_xml = Nokogiri.XML(tax_household.transaction_xml, &:noblanks)
          individual_xml = transaction_xml.at("//airty20a:Form1095AUpstreamDetail")
          if (content = individual_xml.at("//airty20a:RecordSequenceNum")&.content)
            record_sequence_number = content + format("%05d", record_sequence)
            individual_xml.at("//airty20a:RecordSequenceNum").content = record_sequence_number
          end

          @xml_builder.doc.at('//batchreq:Form1095ATransmissionUpstream').add_child(individual_xml)
          record_sequence_number
        end
      end
    end
  end
end
