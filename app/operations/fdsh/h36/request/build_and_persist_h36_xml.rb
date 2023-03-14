# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module H36
    module Request
      # Operation to fetch valid irs_groups per year and build an irs_group_household xml
      class BuildAndPersistH36Xml
        include Dry::Monads[:result, :do]
        include EventSource::Command

        def call(params)
          values                     = yield validate(params)
          valid_transactions         = yield fetch_valid_transactions(values)
          result                     = yield publish(valid_transactions, values)

          Success(result)
        end

        private

        def validate(params)
          return Failure('Please provide transmission') if params[:transmission].blank?

          Success(params)
        end

        def fetch_valid_transactions(values)
          transmission = values[:transmission]
          transactions = transmission.transactions.transmit_pending
          transactions.present? ? Success(transactions) : Failure("No transactions to transmit")
        end

        def publish(valid_transactions, values)
          logger = Logger.new("#{Rails.root}/log/build_h36_xml_director_#{Date.today.strftime('%Y_%m_%d')}.log")
          valid_transactions.no_timeout.each do |transaction|
            transmission_id = values[:transmission].id
            event = event("events.fdsh.h36.build_xml_requested",
                          attributes: { transaction_id: transaction.id.to_s,
                                        transmission_id: transmission_id.to_s,
                                        assistance_year: values[:assistance_year],
                                        month_of_year: values[:month_of_year] })
            event.success.publish
            logger.info("published irs_group build xml event for #{transaction.id} at #{DateTime.now}")

            Success("published irs_group build xml event for #{transaction.id} at #{DateTime.now}")
          rescue StandardError => e
            logger.info("unable to publish irs_group xml event #{transaction.id} due to #{e.inspect}")
            Failure("unable to publish irs_group xml event #{transaction.id} due to #{e.inspect}")
          end

          Success(true)
        end
      end
    end
  end
end
