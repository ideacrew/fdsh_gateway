# frozen_string_literal: true

module H41
  module Transmissions
    module Outbound
      # A model to persist a DataStore synchronization job, its current state and transactions
      class OriginalTransmission < ::Transmittable::Transmission
        include Mongoid::Document
        include Mongoid::Timestamps

        field :batch_reference, type: String
      end
    end
  end
end
