# frozen_string_literal: true

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
