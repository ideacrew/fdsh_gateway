# frozen_string_literal: true

class PdmManifest
  include Mongoid::Document
  include Mongoid::Timestamps
  field :batch_id, type: String
  field :name, type: String
  field :timestamp, type: Date
  field :response, type: String
  field :type, type: String
  field :assistance_year, type: Integer
  field :count, type: Integer
  field :file_generated, type: Boolean
  index({ batch_id: 1 })
  index({ type: 1 })
  index({ assistance_year: 1 })

  embeds_many :pdm_requests

end
