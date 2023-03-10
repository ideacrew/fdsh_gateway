# frozen_string_literal: true

module Fdsh
  module H36
    module Transmissions
      # Operation to BuildTransmission an pending transmission of given kind
      class BuildTransmission
        include Dry::Monads[:result, :do]

        H36_TRANSMISSION_TYPES = [:h36].freeze
        PROCESSING_BATCH_SIZE = 2000

        def call(params)
          values = yield validate(params)
          transmission = yield find_pending_transmission(values)
          _output = yield build_transmission(transmission, values)

          Success(transmission)
        end

        private

        def validate(params)
          return Failure('assistance_year required') unless params[:assistance_year]
          return Failure('month_of_year required') unless params[:month_of_year]

          Success(params)
        end

        def find_pending_transmission(values)
          pending_transmissions = transmission_klass.by_reporting_year_and_month(values[:assistance_year],
                                                                                 values[:month_of_year]).pending
          return Failure("no open transmissions found with #{values.inspect}") unless pending_transmissions.present?
          return Failure("ambiguous transmissions found with #{values.inspect}") if pending_transmissions.count > 1

          Success(pending_transmissions.first)
        end

        def transmission_klass
          "H36::Transmissions::Outbound::MonthOfYearTransmission".constantize
        end

        def build_transmission(transmission, values)
          create_transmission_with(transmission.transactions.transmit_pending, values)
          transmission.update(status: :transmitted)
          Success(true)
        end

        def init_content_file_builder(values)
          options = {
            transmission_kind: 'h36',
            max_month: values[:month_of_year],
            calendar_year: values[:assistance_year]
          }
          ContentFileBuilder.new(options) do |transaction|

            transaction.status = :transmitted
            transaction.transmit_action = :no_transmit
            transaction.save
          end
        end

        def create_transmission_with(transactions, values)
          outbound_folder_name = "h36_transmissions_#{values[:assistance_year]}_#{values[:month_of_year]}"
          ::Fdsh::Transmissions::BatchRequestDirector.new.call({
                                                                 transactions: transactions,
                                                                 transmission_kind: 'h36',
                                                                 outbound_folder_name: outbound_folder_name,
                                                                 transmission_builder: init_content_file_builder(values),
                                                                 batch_size: PROCESSING_BATCH_SIZE
                                                               })
        end
      end
    end
  end
end