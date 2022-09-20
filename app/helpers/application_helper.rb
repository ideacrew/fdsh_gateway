# frozen_string_literal: true

# Shared helpers for the application.
module ApplicationHelper
  def fpl_year(application)
    return unless application
    application_hash = JSON.parse(application, symbolize_names: true)
    application_hash[:assistance_year] - 1
  end

  def application_from_activity(activity)
    return {} unless activity['message']
    payload = JSON.parse(activity['message'].to_json, symbolize_names: true)
    payload[:application]
  end

  def decrypt_message(message)
    return if message.blank?
    decrypted = decrypt(message.first[1])
    return message unless decrypted
    parsed_message = JSON.parse(decrypted)
    xml_string?(parsed_message) ? xp(parsed_message) : parsed_message
  end

  def decrypt(value)
    AcaEntities::Operations::Encryption::Decrypt.new.call({ value: value }).value!
  rescue StandardError => e # rubocop:disable Lint/UselessAssignment
    nil
  end

  def xml_string?(possible_xml)
    possible_xml.to_s.include?("xmlns")
  end

  def xml_formatted_message?(decrypted_message)
    xml_string?(decrypted_message)
  end

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
end
