# frozen_string_literal: true

module Fdsh
  module H36
    module Transmissions
      # Operation to publish an open transmission of given kind
      class ContentFileBuilder
        attr_accessor :document, :transmission_kind, :max_month, :calendar_year

        NAMESPACES = {
          "xmlns" => "urn:us:gov:treasury:irs:common",
          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
          "xmlns:n1" => "urn:us:gov:treasury:irs:msg:monthlyexchangeperiodicdata"
        }.freeze

        def initialize(params = {}, &block)
          @transmission_kind = params[:transmission_kind]
          @max_month = params[:max_month]
          @calendar_year = params[:calendar_year]
          @transaction_event_block = block if block_given?
        end

        def subject_exclusions
          return @subject_exclusions if defined? @subject_exclusions
          @subject_exclusions = Transmittable::SubjectExclusion.by_subject_name('PostedFamily').active
        end

        def can_transmit?(transaction)
          family = transaction.transactable

          subject_exclusions.where(subject_id: family.contract_holder_id).none?
        end

        def record_exception(transaction, error_message)
          transaction.status = :errored
          transaction.transmit_action = :no_transmit
          transaction.transaction_errors = { h36: error_message }
          transaction.save
        end

        def record_denial(transaction)
          transaction.update(status: :denied, transmit_action: :no_transmit)
        end

        def new_document(content_file_number)
          @content_file_number = content_file_number

          @document = Nokogiri::XML::Builder.new do |xml|
            xml['n1'].HealthExchange(NAMESPACES) do
              xml.SubmissionYr Date.today.year.to_s
              xml.SubmissionMonthNum Date.today.month.to_s
              xml.ApplicableCoverageYr @calendar_year
              xml.IndividualExchange do |ind_xml|
                ind_xml.HealthExchangeId "02.ME*.SBE.001.001"
              end
            end
          end
        end

        def append_xml(transaction, transaction_xml, _record_sequence)
          individual_xml = transaction_xml.at("//irs:IRSHouseholdGrp")
          individual_exchange = document.doc.at("//n1:HealthExchange").children.detect do |exchange|
            exchange.name == "IndividualExchange"
          end
          individual_exchange.add_child(individual_xml)
          @transaction_event_block&.call(transaction)
          document
        end

        def filename
          "/EOM_Request_#{format('%05d', @content_file_number)}_#{Time.now.gmtime.strftime('%Y%m%dT%H%M%S%LZ')}.xml"
        end

        def build_manifest_and_transmission(outbound_folder)
          Fdsh::H36::Request::CreateBatchRequestFile.new.call(
            outbound_folder: outbound_folder,
            transmission_kind: transmission_kind
          )
        end
      end
    end
  end
end
