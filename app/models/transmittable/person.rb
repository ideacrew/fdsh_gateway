# frozen_string_literal: true

module Transmittable
  # The subject class of a person to be used by transmittable
  class Person
    include Mongoid::Document
    include Mongoid::Timestamps
    include Transmittable::Subject

    field :correlation_id, type: String
    field :hbx_id, type: String
    field :encrypted_ssn, type: String
    field :surname, type: String
    field :given_name, type: String
    field :dob, type: String
    field :middle_name, type: String

    # indexes
    index({ correlation_id: 1 })
    index({ encrypted_ssn: 1 })
    index({ hbx_id: 1 })

  end
end