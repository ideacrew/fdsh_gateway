# frozen_string_literal: true

# A collection of actions or activities associated with
# a system workflow instance
class Transaction
  include Mongoid::Document
  include Mongoid::Timestamps

  # embedded_in :transactable, polymorphic: true

  field :correlation_id, as: :request_id, type: String
  field :magi_medicaid_application_ciphertext, type: String

  encrypts :magi_medicaid_application

  embeds_many :activities, cascade_callbacks: true
  accepts_nested_attributes_for :activities

  index({ correlation_id: 1 }, { unique: true })
  index({ 'activity.event_key': 1, created_at: 1 })
  index({ 'activity.status': 1, created_at: 1 })
  index({ 'activity.command': 1, created_at: 1 })

  default_scope -> { order(:'activity.created_at'.desc) }
end
