# frozen_string_literal: true

module H41
  module Transmissions
    module Outbound
      # A model to persist a DataStore synchronization job, its current state and transactions
      class OriginalTransmission < ::Transmittable::Transmission
        include Mongoid::Document
        include Mongoid::Timestamps

        has_many :transmission_paths, class_name: '::H41::Transmissions::TransmissionPath', inverse_of: :transmission

        field :reporting_year, type: Integer

        # Scopes
        scope :by_year, ->(reporting_year) { where(reporting_year: reporting_year) }
      end
    end
  end
end
