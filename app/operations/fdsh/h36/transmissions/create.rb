# frozen_string_literal: true

module Fdsh
  module H36
    module Transmissions
      # Operation's job is to find or create an 'open' H41 Transmission of given type.
      class Create
        include Dry::Monads[:result, :do]

        H36_TRANSMISSION_TYPES = [:h36].freeze

        def call(params)
          values = yield validate(params)
          existing_transmissison = yield find(values)
          transmission = yield create(existing_transmissison, values)

          Success(transmission)
        end

        private

        def validate(params)
          return Failure("Please pass in assistance_year") if params[:assistance_year].blank?
          return Failure("Please pass in month_of_year") if params[:month_of_year].blank?

          Success(params)
        end

        def find(values)
          result = Fdsh::H36::Transmissions::Find.new.call({ assistance_year: values[:assistance_year],
                                                             month_of_year: values[:month_of_year] })

          result.failure? ? Success(nil) : result
        end

        def create(existing_transmissison, values)
          return Success(existing_transmissison) if existing_transmissison.present?

          transmission = ::H36::Transmissions::Outbound::MonthOfYearTransmission.new
          transmission.status = :open
          transmission.reporting_year = values[:assistance_year]
          transmission.month_of_year = values[:month_of_year] if values[:month_of_year].present?
          transmission.save!

          Success(transmission)
        end
      end
    end
  end
end
