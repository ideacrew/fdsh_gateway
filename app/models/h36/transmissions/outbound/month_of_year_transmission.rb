# frozen_string_literal: true

module H36
  module Transmissions
    module Outbound
      # A model to persist a DataStore synchronization job, its current state and transactions
      class MonthOfYearTransmission < ::Transmittable::Transmission
        include Mongoid::Document
        include Mongoid::Timestamps

        field :batch_reference, type: String
        field :reporting_year, type: Integer
        field :month_of_year, type: Integer

        index({ reporting_year: 1 })
        index({ reporting_year: 1, month_of_year: 1 })

        # scopes
        scope :by_reporting_year, ->(year) { where(reporting_year: year) }
        scope :by_reporting_year_and_month, ->(year, month) { where(reporting_year: year, month_of_year: month) }

      end
    end
  end
end
