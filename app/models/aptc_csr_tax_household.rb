# frozen_string_literal: true

# Actions or events associated with a single transaction
class AptcCsrTaxHousehold
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :h41_transaction

  embeds_many :activities, cascade_callbacks: true
  accepts_nested_attributes_for :activities

  field :hbx_assigned_id, type: String
  field :h41_transmission, type: String
end
