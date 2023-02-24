# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      # Operation's job is to find or create an 'open' H41 Transmission of given type and reporting_year.
      class FindOrCreate
        include Dry::Monads[:result, :do]

        H41_TRANSMISSION_STATUS_TYPES = [:open, :transmitted].freeze
        H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

        def call(params)
          values       = yield validate(params)
          transmission = yield find(values)
          transmission = yield find_or_create(transmission, values)

          Success(transmission)
        end

        private

        def create(values)
          transmission = case values[:transmission_type]
                         when :corrected
                           ::H41::Transmissions::Outbound::CorrectedTransmission.new
                         when :original
                           ::H41::Transmissions::Outbound::OriginalTransmission.new
                         else
                           ::H41::Transmissions::Outbound::VoidTransmission.new
                         end
          transmission.reporting_year = values[:reporting_year]
          transmission.status = values[:status]
          transmission.save!
          transmission
        end

        def find(values)
          find_result = ::Fdsh::H41::Transmissions::Find.new.call(
            {
              reporting_year: values[:reporting_year],
              status: values[:status],
              transmission_type: values[:transmission_type]
            }
          )
          if find_result.success?
            find_result
          else
            Success(nil)
          end
        end

        def find_or_create(transmission, values)
          return Success(transmission) if transmission.present?

          Success(create(values))
        end

        def validate(params)
          if H41_TRANSMISSION_TYPES.exclude?(params[:transmission_type])
            return Failure("Invalid transmission_type: #{params[:transmission_type]}. Must be one of #{H41_TRANSMISSION_TYPES}.")
          end

          return Failure("Invalid reporting_year: #{params[:reporting_year]}. Must be an integer.") unless params[:reporting_year].is_a?(Integer)

          if H41_TRANSMISSION_STATUS_TYPES.exclude?(params[:status])
            return Failure("Invalid status: #{params[:status]}. Must be one of #{H41_TRANSMISSION_STATUS_TYPES}.")
          end

          Success(params)
        end
      end
    end
  end
end
