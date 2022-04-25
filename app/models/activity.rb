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

  def application_payload
    return {} unless message
    payload = JSON.parse(message.to_json, symbolize_names: true)
    payload[:application]
  end

  def is_request?
    return unless message
    message["request"]
  end

  def is_response?
    return unless message
    message["response"]
  end

  def decrypted_message
  	return unless message
  	if is_request?
  	  pretty_xml(message["request"])
  	elsif is_response?
  	  pretty_xml(message["response"])
    else
      message
    end
  end

  def pretty_xml(xml_text)
    xml = JSON.parse(decrypt(xml_text))
    xp(xml)
  end

  def xp(xml_text)
    xsl =<<XSL
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:template match="/">
    <xsl:copy-of select="."/>
    </xsl:template>
    </xsl:stylesheet>
XSL

    doc = Nokogiri::XML(xml_text)
    xslt = Nokogiri::XSLT(xsl)
    out = xslt.transform(doc)

    out.to_xml
  end

  private

  def decrypt(value)
    AcaEntities::Operations::Encryption::Decrypt.new.call({ value: value }).value!
  end


end
