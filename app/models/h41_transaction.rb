# frozen_string_literal: true

# A collection of actions or activities associated with
class H41Transaction
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :correlation_id, as: :request_id, type: String
  field :primary_hbx_id, type: String
  field :family_hbx_id, type: String
  field :cv3_family, type: String
  field :policy_hbx_id, type: String

  embeds_many :aptc_csr_tax_households, class_name: "::AptcCsrTaxHousehold", cascade_callbacks: true
  embeds_many :activities, cascade_callbacks: true

  accepts_nested_attributes_for :activities, :aptc_csr_tax_households

  index({ correlation_id: 1 })
  index({ primary_hbx_id: 1 })
  index({ family_hbx_id: 1 })
  index({ family: 1 })
  index({ 'activity.created_at': 1, created_at: 1 })
  index({ 'activity.updated_at': 1, created_at: 1 })
  index({ 'activity.event_key': 1, created_at: 1 })
  index({ 'activity.status': 1, created_at: 1 })
  index({ 'activity.command': 1, created_at: 1 })
  index({ 'activity.updated_at': -1, correlation_id: 1 })
  index({ 'activity.updated_at': -1, correlation_id: 1 })
  index({ 'activity.assistance_year': 1 })
  index({ 'activity.application_hbx_id': 1 })
  index({ 'activity.tax_year': 1 })
  index({ "activity.event_key" => 1, "activity.assistance_year" => 1 }, { name: "activity_event_key_assistance_year" })

  default_scope -> { order(:'activity.created_at'.desc) }
end
  