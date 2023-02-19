# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      module Open
        # Operation's job is to find or create an 'open' H41 Transmission of given type.
        class FindOrCreate
          include Dry::Monads[:result, :do]

          H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

          def call(params)
            transmission_type = yield validate(params)
            transmission = yield find_or_create(transmission_type)

            Success(transmission)
          end

          private

          def create(transmission_type)
            transmission = case transmission_type
                           when :corrected
                             ::H41::Transmissions::Outbound::CorrectedTransmission.new
                           when :original
                             ::H41::Transmissions::Outbound::OriginalTransmission.new
                           else
                             ::H41::Transmissions::Outbound::VoidTransmission.new
                           end
            transmission.status = :open
            transmission.save!
            transmission
          end

          def define_missing_constants
            return if ::Transmittable.const_defined?('Transmittable::TRANSACTION_STATUS_TYPES')

            ::Transmittable::Transmission.define_transmission_constants
          end

          def find(transmission_type)
            case transmission_type
            when :corrected
              ::H41::Transmissions::Outbound::CorrectedTransmission.open.first
            when :original
              ::H41::Transmissions::Outbound::OriginalTransmission.open.first
            else
              ::H41::Transmissions::Outbound::VoidTransmission.open.first
            end
          end

          def find_or_create(transmission_type)
            transmission = find(transmission_type)
            if transmission.present?
              define_missing_constants
              Success(transmission)
            else
              Success(create(transmission_type))
            end
          end

          def validate(params)
            if H41_TRANSMISSION_TYPES.include?(params[:transmission_type])
              Success(params[:transmission_type])
            else
              Failure("Invalid transmission type: #{params[:transmission_type]}. Must be one of #{H41_TRANSMISSION_TYPES}")
            end
          end
        end
      end
    end
  end
end
