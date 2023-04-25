# frozen_string_literal: true

module Fdsh
  module Pvc
    module Medicare
      # director accepts assistance year, transactions limit per file and generates batch request zip files.
      class PvcBatchRequestDirector
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        PVC_EVENT_KEY = 'pvc_mdcr_determination_requested'
        OUTBOUND_DIRECTORY = 'pvc_outbound_files'
        PROCESSING_BATCH_SIZE = 5000

        def call(params)
          values          = yield validate(params)
          transactions    = yield query_pvc_requests(values)
          outbound_folder = yield create_outbound_folder(values)
          outbound_folder = yield create_batch_requests(transactions, values, outbound_folder)

          Success(outbound_folder)
        end

        private

        def validate(params)
          return Failure('assistance year missing') unless params[:assistance_year]
          return Failure('transactions per file missing') unless params[:transactions_per_file]

          @batch_size = params[:batch_size] || PROCESSING_BATCH_SIZE

          Success(params)
        end

        def query_pvc_requests(values)
          transactions = Transaction.where(:activities => {
                                             :$elemMatch => {
                                               event_key: PVC_EVENT_KEY,
                                               assistance_year: values[:assistance_year]
                                             }
                                           })

          Success(transactions)
        end

        def batch_request_for(offset, values)
          Transaction.where(:activities => {
                              :$elemMatch => {
                                event_key: PVC_EVENT_KEY,
                                assistance_year: values[:assistance_year]
                              }
                            }).skip(offset).limit(@batch_size)
        end

        def create_outbound_folder(values)
          output_directory = values[:outbound_folder_name] || OUTBOUND_DIRECTORY
          folder = "#{Rails.root}/#{output_directory}"
          outbound_folder = FileUtils.mkdir_p(folder).first

          Success(outbound_folder)
        end

        def create_transaction_xml(application_params, assistance_year)
          Fdsh::Pvc::Medicare::Request::CreateTransactionFile.new.call({ application_payload: application_params, assistance_year: assistance_year })
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
          Fdsh::Pvc::Medicare::Request::CreateBatchRequestFile.new.call({
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

        def process_for_transaction_xml(transaction, values)
          application_params = JSON.parse(transaction.activities.where({
                                                                         event_key: PVC_EVENT_KEY,
                                                                         assistance_year: values[:assistance_year]
                                                                       }).max_by(&:created_at).message['request'])

          result = create_transaction_xml(application_params, values[:assistance_year])
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
          transactions_per_file = values[:transactions_per_file]

          open_transaction_file(outbound_folder)

          while transactions.count > query_offset
            batched_requests = batch_request_for(query_offset, values)
            batched_requests.no_timeout.each do |transaction|
              process_for_transaction_xml(transaction, values)
            end

            query_offset += @batch_size
            batch_offset += @batch_size
            p "Processed #{query_offset} transactions."

            next unless (batch_offset >= transactions_per_file) || (batched_requests.count < @batch_size) || (transactions.count <= query_offset)

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

