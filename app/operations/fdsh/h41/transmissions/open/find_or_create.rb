# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      module Open
        class FindOrCreate
          include Dry::Monads[:result, :do]

          H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

          def call(params)
            transmission_type = yield validate(params)
            transmission = yield find_or_create(transmission_type)

            Success(transmission)
          end

          private

          def create(transaction_type)
            case transmission_type
            when :corrected
              ::H41::Transmissions::Outbound::CorrectedTransmission.create!({ options: {}, status: :open })
            when :original
              ::H41::Transmissions::Outbound::OriginalTransmission.create!({ options: {}, status: :open })
            else
              ::H41::Transmissions::Outbound::VoidTransmission.create!({ options: {}, status: :open })
            end
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

          # TODO: Use find_or_create_by by updating transmission's initialization to set constants with default values when args are not passed in.
          def find_or_create(transmission_type)
            transmission = find(transmission_type)
            Success(transmission) if transmission.present?

            Success(
              create(transaction_type)
            )
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
