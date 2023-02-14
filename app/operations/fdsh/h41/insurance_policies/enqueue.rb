# frozen_string_literal: true

module H41
  module InsurancePolicies
    # Adds a Family and Insurance Policies to the database for H41 transmission to CMS
    class Enqueue
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      # @param [Hash] opts the parameters to create the enqueued H41 notification transaction
      # @option opts [String] :correlation_id The event's unique identifier
      # @option opts [String] :family The Family and affected insurance policies serialized in Canonical Vocubulary (CV) format
      # @option opts [String] :from ('nobody') From address
      def call(params)
        values = yield validate(params)
        policies = yield parse_family(values)
        result = yield enqueue(policies, family)

        Success(result)
      end

      protected

      # Validates params using AcaEntities Family contract
      def validate(_params)
        Success(result)
      end

      # Returns the updated policies and attributes from the Family payload
      def parse_family(_values)
        Success(result)
      end

      # Adds the Family event and its updated policies to the transmission list
      def enqueue(_policies, _family)
        Success(result)
      end
    end
  end
end
