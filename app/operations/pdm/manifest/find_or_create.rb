# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Pdm
  module Manifest
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
        AcaEntities::Pdm::Contracts::ManifestContract.new.call(params)
      end

      # rubocop:disable Style/MultilineBlockChain
      def find_or_create_transaction(values)
        Try() do
          ::PdmManifest.where(type: values[:type],
                              assistance_year: values[:assistance_year],
                              batch_id: values[:batch_id])
        end.bind do |result|
          if result.empty?
            Success(::PdmManifest.new(values))
          else
            manifest = result.first
            manifest.update(values)
            Success(manifest)
            # transaction = result.first
            # activities = values[:activities] || []
            # activities.each do |activity_hash|
            #   activity = ::Activity.new(activity_hash)
            #   transaction.activities << activity
            # end
            # Success(transaction)
          end
        end
      end

      # rubocop:enable Style/MultilineBlockChain

      def persist(instance)
        if instance.save
          Success(instance)
        else
          Failure("Unable to persist Manifest #{instance}")
        end
      end

      def to_entity(document)
        Success(document.serializable_hash(except: :_id).deep_symbolize_keys)
      end

      def log(manifest)
        Logger.new.info(manifest)
      end
    end
  end
end