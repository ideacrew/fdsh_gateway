# frozen_string_literal: true

# The Ssa module encapsulates classes and methods for Social Security Administration related operations.
module Ssa
  # The Person class represents a person in the system.
  # It includes Mongoid::Document to map the class to the MongoDB document.
  # It also includes Mongoid::Timestamps to automatically handle created_at and updated_at timestamps.
  # The class defines fields for correlation_id, hbx_id, encrypted_ssn, surname, given_name, dob, and middle_name.
  #
  # @!attribute correlation_id
  #   @return [String] the correlation_id of the person
  # @!attribute hbx_id
  #   @return [String] the hbx_id of the person
  # @!attribute encrypted_ssn
  #   @return [String] the encrypted Social Security Number of the person
  # @!attribute surname
  #   @return [String] the surname of the person
  # @!attribute given_name
  #   @return [String] the given name of the person
  # @!attribute dob
  #   @return [String] the date of birth of the person
  # @!attribute middle_name
  #   @return [String] the middle name of the person
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
