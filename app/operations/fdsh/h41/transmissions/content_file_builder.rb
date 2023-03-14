# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      # Operation to publish an open transmission of given kind
      class ContentFileBuilder
        PROCESSING_BATCH_SIZE = 5000

        attr_accessor :document
        attr_reader :new_batch_reference, :old_batch_reference, :transmission_kind

        def initialize(params = {}, &block)
          @new_batch_reference = params[:new_batch_reference]
          @old_batch_reference = params[:old_batch_reference]
          @transmission_kind = params[:transmission_kind]
          @transaction_event_block = block if block_given?
        end

        def subject_exclusions
          return @subject_exclusions if defined? @subject_exclusions
          @subject_exclusions = Transmittable::SubjectExclusion.by_subject_name('PostedFamily').active
        end

        def can_transmit?(transaction)
          subject = transaction.transactable
          insurance_policy = subject.insurance_policy
          family = insurance_policy.posted_family

          subject_exclusions.where(subject_id: family.contract_holder_id).none?
        end

        def record_denial(transaction)
          transaction.update(status: :denied, transmit_action: :no_transmit)
        end

        def record_exception(transaction, error_message)
          transaction.status = :errored
          transaction.transmit_action = :no_transmit
          transaction.transaction_errors = { h41: error_message }
          transaction.save
        end

        def new_document(content_file_number)
          @content_file_number = content_file_number

          @document = Nokogiri::XML::Builder.new do |xml|
            xml['batchreq'].Form1095ATransmissionUpstream('xmlns:airty20a' => "urn:us:gov:treasury:irs:ext:aca:air:ty20a",
                                                          'xmlns:irs' => "urn:us:gov:treasury:irs:common",
                                                          'xmlns:batchreq' => "urn:us:gov:treasury:irs:msg:form1095atransmissionupstreammessage",
                                                          'xmlns:batchresp' => "urn:us:gov:treasury:irs:msg:form1095atransmissionexchrespmessage",
                                                          'xmlns:reqack' => "urn:us:gov:treasury:irs:msg:form1095atransmissionexchackngmessage",
                                                          'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance")
          end
        end

        def append_xml(transaction, transaction_xml, record_sequence)
          individual_xml = transaction_xml.at("//airty20a:Form1095AUpstreamDetail")
          if (content = individual_xml.at("//airty20a:RecordSequenceNum")&.content)
            record_sequence_number = content + format("%05d", record_sequence)
            individual_xml.at("//airty20a:RecordSequenceNum").content = record_sequence_number
          end
          document.doc.at('//batchreq:Form1095ATransmissionUpstream').add_child(individual_xml)

          @transaction_event_block&.call(transaction, {
                                           batch_reference: new_batch_reference,
                                           record_sequence_number: record_sequence_number,
                                           content_file_id: format('%05d', @content_file_number).to_s
                                         })
        end

        def filename
          "/EOY_Request_#{format('%05d', @content_file_number)}_#{Time.now.gmtime.strftime('%Y%m%dT%H%M%S%LZ')}.xml"
        end

        def build_manifest_and_transmission(outbound_folder)
          Fdsh::H41::Request::CreateBatchRequestFile.new.call(
            outbound_folder: outbound_folder,
            new_batch_reference: new_batch_reference,
            old_batch_reference: old_batch_reference,
            transmission_kind: transmission_kind
          )
        end
      end
    end
  end
end
