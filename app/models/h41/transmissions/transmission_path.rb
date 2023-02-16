# frozen_string_literal: true

module H41
  module Transmissions
    # A model to persist a the transmission transaction path
    class TransmissionPath
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :transmission, class_name: 'Transmittable::Transmission'
      has_one :transaction, as: :transactable, class_name: 'Transmittable::Transaction'

      # Batch ID/File ID/Record ID
      field :file_reference, type: String

      # TODO: move this to correct model
      field :record_reference, type: String

      def transmission_path
        {
          transmission_id: transmission.batch_reference,
          section_id: file_reference,
          transaction_id: record_reference
        }
      end
    end
  end
end
