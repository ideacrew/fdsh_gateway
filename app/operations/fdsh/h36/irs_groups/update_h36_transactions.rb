# frozen_string_literal: true

module Fdsh
  module H36
    module IrsGroups
      # Update prior h36 transaction and build h36 xmls
      class UpdateH36Transactions
        include Dry::Monads[:result, :do]

        MAX_TRANSMISSION_MONTH = 15

        def call(params)
          values              = yield validate(params)
          result              = yield process(values)

          success(result)
        end

        private

        def validate(params)
          errors = []
          errors << 'assistance_year missing' unless params[:assistance_year]
          errors << 'current_month missing' unless params[:current_month]

          errors.empty? ? Success(params) : Failure(errors)
        end

        def process(values)
          year = values[:assistance_year]
          month = values[:current_month]

          update_and_clone_transactions(year, month)
          # updating prior year transmissions and transactions upto next year's march
          # Ex: For 2022 calendar year we will create and send h36 transmission till March 2023
          update_and_clone_transactions(year - 1, 12 + month) unless (12 + month) > MAX_TRANSMISSION_MONTH
        end

        def update_and_clone_transactions(assistance_year, month_of_year)
          ::Fdsh::H36::IrsGroups::UpdateAndCloneTransactions.new.call({ assistance_year: assistance_year,
                                                                        month_of_year: month_of_year })
        end
      end
    end
  end
end
