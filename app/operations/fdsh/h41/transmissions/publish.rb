# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      # Operation to publish an open transmission of given kind
      class Publish
        include Dry::Monads[:result, :do]

        H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

        def call(params)
          values       = yield validate(params)
          transmission = yield find_open_transmission(values)
          transmission = yield start_processing(transmission)
          _new_transmission = yield create_new_open_transmission(transmission, values)
          _output = yield publish(transmission, values)

          Success(transmission)
        end

        private

        def validate(params)
          return Failure('reporting year required') unless params[:reporting_year]
          return Failure('report_type required ') unless params[:report_type]
          unless params[:report_type] && H41_TRANSMISSION_TYPES.include?(params[:report_type])
            return Failure("report_type must be one #{H41_TRANSMISSION_TYPES.map(&:to_s).join(', ')}")
          end

          Success(params)
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

        def publish(transmission, values)
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

        def init_content_file_builder(values, old_batch_reference = nil)
          ContentFileBuilder.new(transmission_kind: values[:report_type],
                                 old_batch_reference: old_batch_reference) do |transaction, transmission_details|
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
