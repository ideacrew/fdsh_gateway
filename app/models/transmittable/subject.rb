# frozen_string_literal: true

module Transmittable
  # A data model for a unitary transaction
  module Subject
    extend ActiveSupport::Concern

    included do
      has_many :transactions, class_name: '::Transmittable::Transaction'

      # validates :subject_id, uniqueness: true

      # def to_message
      #   # serialize instance to message
      # end
    end

    class_methods do
      # def find(args)
      #   # returns unique transaction by key
      # end
    end
  end
end
