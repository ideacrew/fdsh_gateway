module Transmittable
  class TransactionsTransmissions
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :transmission, class_name: 'Transmittable::Transmission'
    belongs_to :transaction, class_name: 'Transmittable::Transaction'

  end
end
