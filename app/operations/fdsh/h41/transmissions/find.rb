# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      # Operation's job is to find an 'open' H41 Transmission of given type for reporting year.
      class Find
        include Dry::Monads[:result, :do]

        H41_TRANSMISSION_STATUS_TYPES = [:open, :transmitted].freeze
        H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

        def call(params)
          values       = yield validate(params)
          transmission = yield find(values)

          Success(transmission)
        end

        private

        def find(values)
          open_transmission = find_open_transmission(values)

          if open_transmission.present?
            Success(open_transmission)
          else
            Failure(
              "Unable to find OpenTransmission for type: #{values[:transmission_type]}, reporting_year: #{values[:reporting_year]}."
            )
          end
        end

        def find_open_transmission(values)
          open_tranmssions = case values[:transmission_type]
                             when :corrected
                               ::H41::Transmissions::Outbound::CorrectedTransmission.where(
                                 status: values[:status]
                               ).by_year(values[:reporting_year]).order(:created_at.asc)
                             when :original
                               ::H41::Transmissions::Outbound::OriginalTransmission.where(
                                 status: values[:status]
                               ).by_year(values[:reporting_year]).order(:created_at.asc)
                             else
                               ::H41::Transmissions::Outbound::VoidTransmission.where(
                                 status: values[:status]
                               ).by_year(values[:reporting_year]).order(:created_at.asc)
                             end

          values[:latest] ? open_tranmssions.last : open_tranmssions.first
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
