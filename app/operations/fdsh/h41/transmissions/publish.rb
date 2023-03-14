# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      # Operation to publish an open transmission of given kind
      class Publish
        include Dry::Monads[:result, :do]

        H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

        def call(params)
          values = yield validate(params)
          _excluded_families = yield ingest_subject_exclusions(values)
          _expired_families = yield expire_subject_exclusions(values)
          transmission = yield find_open_transmission(values)
          transmission = yield start_processing(transmission)
          _new_transmission = yield create_new_open_transmission(transmission, values)
          _output = yield publish_h41_transmisson(transmission, values)
          _output = yield publish_pdf_reports(transmission, values)

          Success(transmission)
        end

        private

        def validate(params)
          return Failure('reporting year required') unless params[:reporting_year]
          return Failure('report_type required ') unless params[:report_type]
          unless params[:report_type] && H41_TRANSMISSION_TYPES.include?(params[:report_type])
            return Failure("report_type must be one #{H41_TRANSMISSION_TYPES.map(&:to_s).join(', ')}")
          end

          params[:deny_list] ||= []
          params[:allow_list] ||= []

          Success(params)
        end

        def ingest_subject_exclusions(values)
          exclusion_records = Transmittable::SubjectExclusion.by_subject_name('PostedFamily').active

          values[:deny_list].each do |primary_person_id|
            next if exclusion_records.where(subject_id: primary_person_id).present?
            Transmittable::SubjectExclusion.create(
              subject_name: 'PostedFamily',
              subject_id: primary_person_id,
              report_kind: :h41_1095a
            )
          end

          Success(values[:deny_list])
        end

        def expire_subject_exclusions(values)
          exclusion_records = Transmittable::SubjectExclusion.by_subject_name('PostedFamily').active

          values[:allow_list].each do |primary_person_id|
            excluded_subject = exclusion_records.where(subject_id: primary_person_id).first
            excluded_subject&.update(end_at: Time.now)
          end

          Success(values[:allow_list])
        end

        def find_open_transmission(values)
          transmission_klass = transmission_klass_for(values[:report_type])
          transmissions = transmission_klass.by_year(values[:reporting_year]).open

          return Failure("no open transmissions found with #{values.inspect}") unless transmissions.present?
          return Failure("ambiguous transmissions found with #{values.inspect}") if transmissions.count > 1

          Success(transmissions.first)
        end

        def start_processing(transmission)
          transmission.status = :processing

          if transmission.save
            Success(transmission)
          else
            Failure("Failed start processing of transmission due to #{transmission.errors}")
          end
        end

        def create_new_open_transmission(transmission, values)
          new_transmission = transmission.class.new
          new_transmission.reporting_year = values[:reporting_year]
          new_transmission.status = :open
          if new_transmission.save
            Success(new_transmission)
          else
            Failure "Unable to create new open transmission due to #{transmission.errors}"
          end
        end

        def transmission_klass_for(kind)
          "H41::Transmissions::Outbound::#{kind.to_s.camelcase}Transmission".constantize
        end

        def find_transactions_by_original_batch(transmission, values)
          transactions = transmission.transactions.transmit_pending

          transactions.group_by do |transaction|
            subject = transaction.transactable
            transaction_xml = Nokogiri.XML(subject.transaction_xml, &:noblanks)

            if values[:report_type] == :corrected
              transaction_xml.at("//airty20a:CorrectedRecordSequenceNum").content.split('|')[0]
            else
              transaction_xml.at("//airty20a:VoidedRecordSequenceNum").content.split('|')[0]
            end
          end
        end

        def publish_h41_transmisson(transmission, values)
          if values[:report_type] == :original
            create_transmission_with(transmission.transactions.transmit_pending, values)
          else
            find_transactions_by_original_batch(transmission, values).each do |batch_reference, transactions|
              create_transmission_with(transactions, values, batch_reference)
            end
          end

          transmission.update(status: :transmitted)
          Success(true)
        end

        def publish_pdf_reports(transmission, values)
          Fdsh::H41::Transmissions::Publish1095aPayload.new.call({ transmission: transmission,
                                                                   reporting_year: values[:reporting_year],
                                                                   report_type: values[:report_type] })
        end

        def create_batch_reference_with(batch_time)
          batch_time.gmtime.strftime("%Y-%m-%dT%H:%M:%SZ")
        end

        def default_batch_time
          Time.now + 1.hours
        end

        def create_batch_reference
          new_batch_reference = create_batch_reference_with(default_batch_time)
          return @recent_new_batch_reference = new_batch_reference unless defined? @recent_new_batch_reference

          if @recent_new_batch_reference == new_batch_reference
            new_batch_reference = create_batch_reference_with(default_batch_time + 1.seconds)
            @recent_new_batch_reference = new_batch_reference
          end
          new_batch_reference
        end

        def init_content_file_builder(values, old_batch_reference = nil)
          options = {
            transmission_kind: values[:report_type],
            old_batch_reference: old_batch_reference,
            new_batch_reference: create_batch_reference
          }

          ContentFileBuilder.new(options) do |transaction, transmission_details|

            transaction.status = :transmitted
            transaction.transmit_action = :no_transmit
            transaction.save

            transmission_path = transaction.transmission.transmission_paths.build(
              transmission_details.merge(transaction_id: transaction.id)
            )
            transmission_path.save
          end
        end

        def create_transmission_with(transactions, values, old_batch_reference = nil)
          ::Fdsh::Transmissions::BatchRequestDirector.new.call({
                                                                 transactions: transactions,
                                                                 transmission_kind: values[:report_type],
                                                                 old_batch_reference: old_batch_reference,
                                                                 outbound_folder_name: 'h41_transmissions',
                                                                 transmission_builder: init_content_file_builder(values, old_batch_reference)
                                                               })
        end
      end
    end
  end
end
