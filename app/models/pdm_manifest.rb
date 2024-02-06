# frozen_string_literal: true

# The PdmManifest class represents a manifest in the system.
# It includes Mongoid::Document to map the class to the MongoDB document.
# It also includes Mongoid::Timestamps to automatically handle created_at and updated_at timestamps.
# The class defines fields for batch_ids, file_names, name, timestamp, response,
# type, assistance_year, initial_count, generated_count, and file_generated.
# It embeds many PdmRequest objects and accepts nested attributes for them.
#
# @!attribute batch_ids
#   @return [Array] the batch_ids of the manifest
# @!attribute file_names
#   @return [Array] the file_names of the manifest
# @!attribute name
#   @return [String] the name of the manifest
# @!attribute timestamp
#   @return [Date] the timestamp of the manifest
# @!attribute response
#   @return [String] the response of the manifest
# @!attribute type
#   @return [String] the type of the manifest
# @!attribute assistance_year
#   @return [Integer] the assistance_year of the manifest
# @!attribute initial_count
#   @return [Integer] the initial_count of the manifest
# @!attribute generated_count
#   @return [Integer] the generated_count of the manifest
# @!attribute file_generated
#   @return [Boolean] the file_generated status
class PdmManifest
  include Mongoid::Document
  include Mongoid::Timestamps
  field :batch_ids, type: Array, default: []
  field :file_names, type: Array, default: []
  field :name, type: String
  field :timestamp, type: Date
  field :response, type: String
  field :type, type: String
  field :assistance_year, type: Integer
  field :initial_count, type: Integer
  field :generated_count, type: Integer

  # the design is based on the assumption
  # that the process will not be run concurrently
  # we will have to wait until the first one finishes
  field :file_generated, type: Boolean

  index({ batch_ids: 1 })
  index({ type: 1 })
  index({ assistance_year: 1 })

  index({ 'pdm_requests.subject_id': 1, created_at: 1 })

  embeds_many :pdm_requests
  accepts_nested_attributes_for :pdm_requests

end
