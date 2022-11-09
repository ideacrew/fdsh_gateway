# frozen_string_literal: true

# Fdsh::Rrv::Medicare::RrvBatchRequestDirector.new.call({
#   assistance_year: 2022,
#   transactions_per_file: 3,
#   outbound_folder_name: 'rrv_outbound_files'
# })

module Fdsh
  module Rrv
    module Medicare
      class RrvBatchRequestDirector
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        RRV_EVENT_KEY = "rrv_mdcr_determination_requested"

        def call(params)
          values          = yield validate(params)
          transactions    = yield query_rrv_requests(values)
          outbound_folder = yield create_batch_requests(transactions, values)

          Success(outbound_folder)
        end

        private

        def validate(params)
          return Failure('assistance year missing') unless params[:assistance_year]
          return Failure('transactions per file missing') unless params[:transactions_per_file]
          return Failure('outbound folder name missing') unless params[:outbound_folder_name]
  
          Success(params)
        end

        def query_rrv_requests(values)
          transactions = Transaction.where(:activities => {
            :$elemMatch => {
              event_key: RRV_EVENT_KEY,
              assistance_year: values[:assistance_year]
            }
          })

          Success(transactions)
        end

        def create_batch_requests(transactions, values)
          offset = 0
          while transactions.count > offset
            transactions_set = transactions.skip(offset).limit(values[:transactions_per_file])

            application_payloads = transactions_set.collect do |transaction|
              JSON.parse(transaction.activities.where({
                event_key: RRV_EVENT_KEY,
                assistance_year: values[:assistance_year]
              }).max_by(&:created_at).message['request'])
            end

            Fdsh::Rrv::Medicare::Request::CreateBatchRequestFile.new.call(application_payloads, values)
            offset += values[:transactions_per_file]
          end

          Success(values[:outbound_folder_name])
        end
      end
    end
  end
end
