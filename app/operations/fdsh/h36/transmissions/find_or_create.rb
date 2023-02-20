# frozen_string_literal: true

module Fdsh
  module H36
    module Transmissions
      # Operation's job is to find or create an 'open' H41 Transmission of given type.
      class FindOrCreate
        include Dry::Monads[:result, :do]

        H36_TRANSMISSION_TYPES = [:h36].freeze

        def call(params)
          values = yield validate(params)
          transmission = yield find_or_create(values)

          Success(transmission)
        end

        private

        def validate(params)
          return Failure("Please pass in assistance_year") if params[:assistance_year].blank?

          Success(params)
        end

        def create_transmission(values)
          transmission = ::H36::Transmissions::Outbound::MonthOfYearTransmission.new
          transmission.status = :open
          transmission.reporting_year = values[:assistance_year]
          transmission.reporting_month = values[:month] if values[:month].present?
          transmission.save!
          transmission
        end

        def find_transmission(params)
          ::H36::Transmissions::Outbound::MonthOfYearTransmission.open
                                                                 .where(reporting_year: params[:assistance_year]).first
        end

        def find_or_create(params)
          transmission = find_transmission(params)
          if transmission.present?
            Success(transmission)
          else
            Success(create_transmission(params))
          end
        end
      end
    end
  end
end
