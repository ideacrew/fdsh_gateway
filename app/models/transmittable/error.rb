# frozen_string_literal: true

module Transmittable
  # Persisted errors for transmittable objects
  class Error
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :errorable, polymorphic: true, inverse_of: :errorable, index: true

    field :key, type: String
    field :message, type: String
  end
end
