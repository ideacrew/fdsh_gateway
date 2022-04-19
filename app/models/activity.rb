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

  def event_key_label
  	return unless event_key
  	event_key.humanize.upcase
  end

  def response_code
  	return "no message" unless message
  	#return  "no response" unless message["response_metadata"]
  	JSON.parse(message.to_json).keys
  end
end
