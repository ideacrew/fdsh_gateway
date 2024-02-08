# frozen_string_literal: true

# The PdmRequest class represents a request in the system.
# It includes Mongoid::Document to map the class to the MongoDB document.
# It also includes Mongoid::Timestamps to automatically handle created_at and updated_at timestamps.
# The class defines fields for subject_id, command, request_payload, response_payload, and document_identifier.
# It is embedded in the PdmManifest class.
#
# @!attribute subject_id
#   @return [String] the subject_id of the request
# @!attribute command
#   @return [String] the command of the request
# @!attribute request_payload
#   @return [String] the payload of the request
# @!attribute response_payload
#   @return [String] the payload of the response
# @!attribute document_identifier
#   @return [Hash] a secondary ID, e.g., foreign key, tied to an associated document
class PdmRequest
  include Mongoid::Document
  include Mongoid::Timestamps

  field :subject_id, type: String
  field :command, type: String
  field :request_payload, type: String
  field :response_payload, type: String
  # used for storing a secondary ID, e.g., foreign key, tied to an associated document
  field :document_identifier, type: Hash

  embedded_in :pdm_manifest

  validates :subject_id, uniqueness: true
end
