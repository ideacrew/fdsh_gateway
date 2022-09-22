# frozen_string_literal: true

# A collection of actions or activities associated with
# a system workflow instance
class Transaction
  include Mongoid::Document
  include Mongoid::Timestamps

  # embedded_in :transactable, polymorphic: true

  field :correlation_id, as: :request_id, type: String
  field :magi_medicaid_application, type: String
  field :application_id, type: String
  field :primary_hbx_id, type: String

  embeds_many :activities, cascade_callbacks: true
  accepts_nested_attributes_for :activities

  index({ correlation_id: 1 }, { unique: true })
  index({ application_id: 1 })
  index({ primary_hbx_id: 1 })
  index({ 'activity.created_at': 1, created_at: 1 })
  index({ 'activity.updated_at': 1, created_at: 1 })
  index({ 'activity.event_key': 1, created_at: 1 })
  index({ 'activity.status': 1, created_at: 1 })
  index({ 'activity.command': 1, created_at: 1 })

  default_scope -> { order(:'activity.created_at'.desc) }

  def magi_medicaid_application_hash
    if magi_medicaid_application
      JSON.parse(magi_medicaid_application, symbolize_names: true)
    elsif application_activity
      application_activity
    else
      {}
    end
  end

  def application_activity
    activities.detect(&:application_payload)&.application_payload
  end

  def applicants
    magi_medicaid_application_hash[:applicants] || []
  end

  def primary_applicant
    applicants.detect { |applicant| applicant[:is_primary_applicant] } || {}
  end

  def assistance_year
    magi_medicaid_application_hash[:assistance_year]
  end

  def fpl_year
    return unless assistance_year
    assistance_year - 1
  end
end
