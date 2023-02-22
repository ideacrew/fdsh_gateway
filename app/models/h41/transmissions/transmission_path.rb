# frozen_string_literal: true

module H41
  module Transmissions
    # A model to persist the transmission transaction path
    class TransmissionPath
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :transaction, class_name: '::Transmittable::Transaction', inverse_of: :transaction_transmission_path
      belongs_to :transmission, class_name: '::Transmittable::Transmission', inverse_of: :transmission_paths

      field :batch_reference, type: String
      field :content_file_id, type: String
      field :record_sequence_number, type: String

      # refactor below to return corrected/void sequence number with above fields
      def transmission_path
        [
          batch_reference, content_file_id, record_sequence_number
        ].join('|')
      end
    end
  end
end
