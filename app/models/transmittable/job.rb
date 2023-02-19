# frozen_string_literal: true

module Transmittable
  # A data model for a unitary transaction
  module Job
    # Time boundary parameters for the job
    field :time_span_start, type: DateTime
    field :time_span_end, type: DateTime

    # State for the job
    field :status, type: Symbol
    field :started_at, type: DateTime, default: -> { Time.now }
    field :completed_at, type: DateTime

    index({ time_span_end: -1 })

    scope :lastest_time_span_end, -> { order_by(time_span_end: -1).first }
  end
end
