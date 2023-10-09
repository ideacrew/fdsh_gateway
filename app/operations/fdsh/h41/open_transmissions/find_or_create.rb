# frozen_string_literal: true

module Fdsh
  module H41
    module OpenTransmissions
      # Operation's job is to find or create 'open' H41 Transmissions for the given reporting_year.
      # Example:
      #   During renewals, the system date is advanced to September 15th.
      #   This operation creates H41 OpenTransmissions for the reporting_year to handle incoming transactions.
      class FindOrCreate
        include Dry::Monads[:result, :do]

        H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

        # @param [Hash] opts The options to create Open H41 Transmissions
        # @option opts [Integer] :reporting_year required
        # @return [Dry::Monads::Result]
        def call(params)
          reporting_year = yield validate(params)
          result = yield find_or_create_open_transmission(reporting_year)

          Success(result)
        end

        private

        def validate(params)
          if params[:reporting_year].is_a?(Integer)
            Success(params[:reporting_year])
          else
            Failure("Invalid reporting_year: #{params[:reporting_year]}. Must be an integer.")
          end
        end

        def find_or_create_open_transmission(reporting_year)
          all_results = H41_TRANSMISSION_TYPES.inject({}) do |results, transmission_type|
            result = find_or_create(reporting_year, transmission_type)
            results[transmission_type] = result.failure? ? result.failure : result.success
            results
          end

          # Returns a hash with keys as transmission_type and values as result(a Failure string or a Success transmission)
          if all_results.values.all? { |result| result.is_a?(::Transmittable::Transmission) }
            Success(all_results)
          else
            Failure(all_results)
          end
        end

        def find_or_create(reporting_year, transmission_type)
          ::Fdsh::H41::Transmissions::FindOrCreate.new.call(
            {
              reporting_year: reporting_year,
              status: :open,
              transmission_type: transmission_type
            }
          )
        end
      end
    end
  end
end
