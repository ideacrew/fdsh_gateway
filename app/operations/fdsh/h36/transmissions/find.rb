# frozen_string_literal: true

module Fdsh
  module H36
    module Transmissions
      # Operation's job is to find or create an 'open' H41 Transmission of given type.
      class Find
        include Dry::Monads[:result, :do]

        def call(params)
          values = yield validate(params)
          transmission = yield find(values)

          Success(transmission)
        end

        private

        def validate(params)
          return Failure("Please pass in assistance_year") if params[:assistance_year].blank?
          return Failure("Please pass in month_of_year") if params[:month_of_year].blank?

          Success(params)
        end

        def find(params)
          result = ::H36::Transmissions::Outbound::MonthOfYearTransmission.open.where(
            reporting_year: params[:assistance_year],
            month_of_year: params[:month_of_year]
          ).first

          result.present? ? Success(result) : Failure("Unable to find open transmission")
        end
      end
    end
  end
end
