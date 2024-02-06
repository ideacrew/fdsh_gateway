# frozen_string_literal: true

# The Transmittable module encapsulates classes and methods for transmitting data.
module Transmittable
  # The Application class represents an application in the system.
  # It includes Mongoid::Document to map the class to the MongoDB document.
  # It also includes Mongoid::Timestamps to automatically handle created_at and updated_at timestamps.
  # The class defines fields for hbx_id and primary_applicant_hbx_id.
  #
  # @!attribute hbx_id
  #   @return [String] the hbx_id of the application
  # @!attribute primary_applicant_hbx_id
  #   @return [String] the hbx_id of the primary applicant
  class Application
    include Mongoid::Document
    include Mongoid::Timestamps
    include Transmittable::Subject

    field :hbx_id, type: String
    field :primary_applicant_hbx_id, type: String

    # indexes
    index({ hbx_id: 1 })
    index({ primary_applicant_hbx_id: 1 })

  end
end
