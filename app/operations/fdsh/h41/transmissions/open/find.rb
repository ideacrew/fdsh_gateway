# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      module Open
        # Operation's job is to find an 'open' H41 Transmission of given type for reporting year.
        class Find
          include Dry::Monads[:result, :do]

          H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

          def call(params)
            values       = yield validate(params)
            transmission = yield find(values)

            Success(transmission)
          end

          private

          def define_missing_constants
            return if ::Transmittable.const_defined?('Transmittable::TRANSACTION_STATUS_TYPES')

            ::Transmittable::Transmission.define_transmission_constants
          end

          def find(values)
            open_transmission = find_open_transmission(values[:transmission_type], values[:reporting_year])

            if open_transmission.present?
              define_missing_constants
              Success(open_transmission)
            else
              Failure(
                "Unable to find OpenTransmission for type: #{values[:transmission_type]}, reporting_year: #{values[:reporting_year]}."
              )
            end
          end

          def find_open_transmission(transmission_type, reporting_year)
            case transmission_type
            when :corrected
              ::H41::Transmissions::Outbound::CorrectedTransmission.open.by_year(reporting_year).first
            when :original
              ::H41::Transmissions::Outbound::OriginalTransmission.open.by_year(reporting_year).first
            else
              ::H41::Transmissions::Outbound::VoidTransmission.open.by_year(reporting_year).first
            end
          end

          def validate(params)
            if H41_TRANSMISSION_TYPES.exclude?(params[:transmission_type])
              return Failure("Invalid transmission_type: #{params[:transmission_type]}. Must be one of #{H41_TRANSMISSION_TYPES}.")
            end
            return Failure("Invalid reporting_year: #{params[:reporting_year]}. Must be an integer.") unless params[:reporting_year].is_a?(Integer)

            Success(params)
          end
        end
      end
    end
  end
end
