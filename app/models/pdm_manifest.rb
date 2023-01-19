# frozen_string_literal: true

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
