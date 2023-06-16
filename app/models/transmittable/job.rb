# frozen_string_literal: true

module Transmittable
  # A data model for a unitary transaction
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps

  end
end
