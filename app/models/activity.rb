# frozen_string_literal: true

# Actions or events associated with a single transaction
class Activity
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :transaction

  field :correlation_id, type: String
  field :command, type: String
  field :event_key, type: String
  field :message, type: Hash
  field :status, type: StringifiedSymbol
end
