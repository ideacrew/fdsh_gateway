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
    JSON.generate(message)
  end

  def decrypted_message
    return unless message
    return if message.empty?
    decrypted = decrypt(message.first[1])
    return message unless decrypted
    parsed_message = JSON.parse(decrypted)
    xml_string?(parsed_message) ? xp(parsed_message) : parsed_message
  end

  def xml_formatted_message?
    xml_string?(decrypted_message)
  end

  private

  def xp(xml_text)
    xsl = <<XSL
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:template match="/">
    <xsl:copy-of select="."/>
    </xsl:template>
    </xsl:stylesheet>
XSL

    doc = Nokogiri::XML(xml_text)
    return xml_text unless doc.errors.blank?
    xslt = Nokogiri::XSLT(xsl)
    out = xslt.transform(doc)

    out.to_xml
  end

  def xml_string?(possible_xml)
    possible_xml.to_s.include?("xmlns")
  end

  def decrypt(value)
    AcaEntities::Operations::Encryption::Decrypt.new.call({ value: value }).value!
  rescue StandardError => e # rubocop:disable Lint/UselessAssignment
    nil
  end

end
