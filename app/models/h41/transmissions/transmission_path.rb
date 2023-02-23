# frozen_string_literal: true

module H41
  module Transmissions
    # A model to persist the transmission transaction path
    class TransmissionPath
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :transaction, class_name: '::Transmittable::Transaction', inverse_of: :transaction_transmission_path, index: true
      belongs_to :transmission, class_name: '::Transmittable::Transmission', inverse_of: :transmission_paths, index: true

      field :batch_reference, type: String
      field :content_file_id, type: String
      field :record_sequence_number, type: String

      def record_sequence_number_path
        [
          batch_reference, content_file_id, record_sequence_number
        ].join('|')
      end
    end
  end
end
