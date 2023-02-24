# frozen_string_literal: true

module Transmittable
  # A single workflow event instance for transmission to an external service
  class SubjectExclusion
    include Mongoid::Document
    include Mongoid::Timestamps

    REPORT_KINDS = [:h41_1095a, :h36].freeze

    field :report_kind, type: Symbol
    field :subject_name, type: String
    field :subject_id, type: String
    field :start_at, type: DateTime, default: -> { Time.now }
    field :end_at, type: DateTime

    scope :by_subject_name, ->(name) { where(subject_name: name)}
    scope :active,  -> { where('$or': [{ :end_at => nil }, { :end_at.gte => Time.now }])}
    scope :expired, -> { where('$and': [{ :end_at.ne => nil }, { :end_at.lte => Time.now }])}
  end
end
