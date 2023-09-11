# frozen_string_literal: true

module Transmittable
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
