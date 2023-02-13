# frozen_string_literal: true

module H41
  # A model to persist a DataStore synchronization job, its current state and transactions
  class OriginalTransmission < ::Transmittable::Transmission
    include Mongoid::Document
    include Mongoid::Timestamps
    include Transmittable::Transmission

    SUBJECT_CLASS_NAME = 'H41::InsurancePolicies::TaxHousehold'
    TRANSMIT_ACTION_TYPES = %i[transmit no_transmit blocked].freeze

    TRANSACTION_TYPES = %i[original corrected void]

    # Only populated for Corrected and Void transactions
    # Batch ID/File ID/Record ID
    field :original_transmission_path, type: String
    field :transmission_path, type: String
    scope :is_original_transmission, -> { where(:original_transmission_path.eq => :transmission_path) }

    private

    # Guard for start dates in the future and those that precede a prior sync operation
    def validate_time_span_start
      start_at = [[time_span_start, Time.now].min, lastest_end_date].max
      write_attribute(:time_span_start, start_at)
    end

    # Guard for end dates in the future that if persisted will result in time gaps due to
    # time_span_start validation
    def validate_time_span_end
      end_at = [end_at, Time.now].min
      write_attribute(:time_span_end, end_at)
    end

    def validate_time_span
      time_span_sttart < time_span_end
    end
  end
end
