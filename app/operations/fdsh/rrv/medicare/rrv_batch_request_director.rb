# frozen_string_literal: true

module Fdsh
  module Rrv
    module Medicare
      # director accepts assistance year, transactions limit per file and generates batch request zip files.
      class RrvBatchRequestDirector
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        RRV_EVENT_KEY = "rrv_mdcr_determination_requested"
        PROCESSING_BATCH_SIZE = 100

        def call(params)
          values          = yield validate(params)
          transactions    = yield query_rrv_requests(values)
          outbound_folder = yield create_outbound_folder(values)
          outbound_folder = yield create_batch_requests(transactions, values, outbound_folder)

          Success(outbound_folder)
        end

        private

        def validate(params)
          return Failure('assistance year missing') unless params[:assistance_year]
          return Failure('transactions per file missing') unless params[:transactions_per_file]
          return Failure('outbound folder name missing') unless params[:outbound_folder_name]
          @batch_size = params[:batch_size] if params[:batch_size]

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

        def processing_batch_size
          @batch_size || PROCESSING_BATCH_SIZE
        end

        def batch_request_for(offset, values)
          Transaction.where(:activities => {
                              :$elemMatch => {
                                event_key: RRV_EVENT_KEY,
                                assistance_year: values[:assistance_year]
                              }
                            }).skip(offset).limit(processing_batch_size)
        end

        def create_outbound_folder(values)
          folder = "#{Rails.root}/#{values[:outbound_folder_name]}"
          outbound_folder = FileUtils.mkdir_p(folder).first

          Success(outbound_folder)
        end

        def create_transaction_xml(application_params, _outbound_folder)
          Fdsh::Rrv::Medicare::Request::CreateTransactionFile.new.call({ application_payload: [application_params] })
        end

        def open_transaction_file(_outbound_folder)
          @xml_builder = Nokogiri::XML::Builder.new do |xml|
            xml.EESDSHBatchRequestData do
              xml.IndividualRequests
            end
          end
          @applicants_count = 0
        end

        def close_transaction_file(outbound_folder)
          xml_string = @xml_builder.to_xml(:indent => 2, :encoding => 'UTF-8')
          file_name = outbound_folder + "/MDCR_Request_00001_#{Time.now.gmtime.strftime('%Y%m%dT%H%M%S%LZ')}.xml"
          @transaction_file = File.open(file_name, "w")
          @transaction_file.write(xml_string.to_s)
          @transaction_file.close
        end

        def create_batch_file(outbound_folder)
          Fdsh::Rrv::Medicare::Request::CreateBatchRequestFile.new.call({
                                                                          transaction_file: @transaction_file,
                                                                          applicants_count: @applicants_count,
                                                                          outbound_folder: outbound_folder
                                                                        })
        end

        def append_xml(transaction_xml)
          individual_xml = Nokogiri.XML(transaction_xml, &:noblanks)
          individual_xml.at('IndividualRequests').children.each do |child_node|
            @xml_builder.doc.at('IndividualRequests').add_child(child_node)
          end
        end

        def process_for_transaction_xml(transaction, values, outbound_folder)
          application_params = JSON.parse(transaction.activities.where({
                                                                         event_key: RRV_EVENT_KEY,
                                                                         assistance_year: values[:assistance_year]
                                                                       }).max_by(&:created_at).message['request'])

          result = create_transaction_xml(application_params, outbound_folder)
          if result.success?
            transaction_xml, applicants_count = result.success
            append_xml(transaction_xml)
            @applicants_count += applicants_count
          else
            p "xml generation failed for #{transaction.id} due to #{result.failure}"
          end
        end

        def create_batch_requests(transactions, values, outbound_folder)
          batch_offset = 0
          query_offset = 0

          open_transaction_file(outbound_folder)

          while transactions.count > query_offset
            batched_requests = batch_request_for(query_offset, values)
            batched_requests.no_timeout.each do |transaction|
              process_for_transaction_xml(transaction, values, outbound_folder)
            end

            query_offset += processing_batch_size
            batch_offset += processing_batch_size
            p "Processed #{query_offset} transactions."

            # rubocop:disable Layout/LineLength
            unless (batch_offset >= values[:transactions_per_file]) || (batched_requests.count < processing_batch_size) || (transactions.count <= query_offset)
              next
            end
            # rubocop:enable Layout/LineLength
            batch_offset = 0
            close_transaction_file(outbound_folder)
            create_batch_file(outbound_folder)
            open_transaction_file(outbound_folder)
          end

          Success(values[:outbound_folder_name])
        end
      end
    end
  end
end

