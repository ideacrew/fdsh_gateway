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
        field :reporting_month, type: Integer

        # scopes
        scope :by_reporting_year, ->(year) { where(reporting_year: year) }

      end
    end
  end
end
