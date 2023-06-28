# frozen_string_literal: true

module Transmittable
  # A data model for a unitary transaction
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps

    has_many :transmissions, class_name: 'Transmittable::Transmission'

    field :job_id, type: String
    field :saga_id, type: String
    field :key, type: String
    field :title, type: String
    field :description, type: String
    field :publish_on, type: Date
    field :expire_on, type: DateTime
    field :started_at, type: DateTime
    field :ended_at, type: DateTime
    field :time_to_live, type: Integer
    field :process_status, type: Hash
    # field :errors, type: Array
    field :allow_list, type: Array
    field :deny_list, type: Array
    field :message_id, type: String

  end
end
