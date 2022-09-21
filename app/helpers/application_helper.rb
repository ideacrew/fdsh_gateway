# frozen_string_literal: true

# Shared helpers for the application.
module ApplicationHelper
  def fpl_year(application)
    return unless application.present?
    application_hash = JSON.parse(application)
    assistance_year = application_hash&.dig('assistance_year')
    assistance_year - 1 if assistance_year
  end

  def application_from_activity(correlation_id)
    transaction = Transaction.where(correlation_id: correlation_id)
    return "{}" unless transaction.present?

    transaction.first.activities.detect(&:application_payload)&.application_payload.to_json
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
