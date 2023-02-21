# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      module Open
        # Operation's job is to find or create an 'open' H41 Transmission of given type and reporting_year.
        class FindOrCreate
          include Dry::Monads[:result, :do]

          H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

          def call(params)
            values       = yield validate(params)
            transmission = yield find(values)
            transmission = yield find_or_create(transmission, values)

            Success(transmission)
          end

          private

          def create(transmission_type, reporting_year)
            transmission = case transmission_type
                           when :corrected
                             ::H41::Transmissions::Outbound::CorrectedTransmission.new
                           when :original
                             ::H41::Transmissions::Outbound::OriginalTransmission.new
                           else
                             ::H41::Transmissions::Outbound::VoidTransmission.new
                           end
            transmission.reporting_year = reporting_year
            transmission.status = :open
            transmission.save!
            transmission
          end

          def find(values)
            find_result = ::Fdsh::H41::Transmissions::Open::Find.new.call(
              {
                reporting_year: values[:reporting_year],
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

            Success(
              create(values[:transmission_type], values[:reporting_year])
            )
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
