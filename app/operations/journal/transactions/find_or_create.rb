# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Journal
  module Transactions
    # Upsert a Transaction with associated Activity.
    # The operation will first search for a record matching :correlation_id
    # parameter and update it with the :activity parameter.  If a match
    # isn't found, it will create a new record with the :correlation_id
    # and :activity parameters
    class FindOrCreate
      include Dry::Monads[:try, :result, :do]

      # @param [Hash] opts The options to create application object
      # @option opts [String] :correlation_id
      # @option opts [String] :activities
      # @return [Dry::Monads::Result]
      def call(params)
        values = yield validate_params(params)
        instance = yield find_or_create_transaction(values.to_h)
        document = yield persist(instance)
        transaction = yield to_entity(document)

        # log(transaction)
        Success(transaction)
      end

      private

      def validate_params(params)
        Journal::TransactionContract.new.call(params)
      end

      # rubocop:disable Style/MultilineBlockChain
      def find_or_create_transaction(values)
        Try() do
          ::Transaction.where(correlation_id: values[:correlation_id]) # correlation_id is a unique identifier
        end.bind do |result|
          if result.empty?
            Success(::Transaction.new(values))
          else
            transaction = result.first
            transaction.magi_medicaid_application = values[:magi_medicaid_application] if values[:magi_medicaid_application]
            transaction.application_id = values[:application_id] if values[:application_id]
            activities = values[:activities] || []
            activities.each do |activity_hash|
              activity = ::Activity.new(activity_hash)
              transaction.activities << activity
            end
            Success(transaction)
          end
        end
      end

      # rubocop:enable Style/MultilineBlockChain

      def persist(instance)
        if instance.save
          Success(instance)
        else
          Failure("Unable to persist transaction #{instance}")
        end
      end

      def to_entity(document)
        Success(document.serializable_hash(except: :_id).deep_symbolize_keys)
      end

      def log(transaction)
        Logger.new.info(transaction)
      end
    end
  end
end
