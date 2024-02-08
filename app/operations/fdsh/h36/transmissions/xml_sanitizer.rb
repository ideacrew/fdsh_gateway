# frozen_string_literal: true

module Fdsh
  module H36
    module Transmissions
      # santizes xml
      class XmlSanitizer
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        NAMESPACES = {
          "xmlns" => "urn:us:gov:treasury:irs:common",
          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
          "xmlns:n1" => "urn:us:gov:treasury:irs:msg:monthlyexchangeperiodicdata"
        }.freeze

        def call(params)
          values = yield validate(params)
          values = yield load_xml_document(values)
          xml_doc = yield sanitize(values)

          Success(xml_doc)
        end

        private

        def validate(params)
          return Failure("xml string expected") unless params[:xml_string]

          Success(params)
        end

        def load_xml_document(values)
          xml_doc = Nokogiri::XML(values[:xml_string])

          Success(xml_doc)
        end

        def sanitize(xml_doc)
          xml_doc.xpath('//xmlns:IndividualExchange', NAMESPACES).each do |node|
            chop_special_characters(node)
          end

          Success(xml_doc.to_xml(:indent => 2, :encoding => 'UTF-8'))
        end

        def chop_special_characters(node)
          fetch_ssn(node)
          %w[PersonFirstName PersonMiddleName PersonLastName AddressLine1Txt AddressLine2Txt CityNm USZIPCd].each do |ele|
            node.xpath("//xmlns:#{ele}", NAMESPACES).each do |xml_tag|
              if xml_tag.content.match(/(-{1,2}|'|\#|"|&|<|>|\.|,|\s{2})/)
                content = xml_tag.content.gsub(/\s+/, " ").gsub(/(-{1,2}|'|\#|"|&|<|>|\.|,|\(|\)|_)/, "")
                xml_tag.content = content
              end

              xml_tag.content = xml_tag.content.gsub(/\s{2}/, ' ').gsub("-", ' ') if ele == "CityNm"

              sanitize_zipcode(xml_tag) if ele == "USZIPCd"

              if ['AddressLine1Txt', "AddressLine2Txt"].include?(ele)
                xml_tag.content = xml_tag.content.gsub(/\s+/, " ").truncate(35, :omission => '').strip
              end

              if ['PersonFirstName', 'PersonMiddleName', 'PersonLastName'].include?(ele)
                xml_tag.content = xml_tag.content.gsub(/\s+/, " ").truncate(20, :omission => '').strip
              end
            end
          end
          node
        end

        def fetch_ssn(node)
          node.xpath("//xmlns:SSN", NAMESPACES).each do |ssn_node|
            ssn_node.content = ssn_node.content.strip.gsub("-", "")
          end
        end

        def sanitize_zipcode(node)
          node.xpath("//xmlns:USZIPCd", NAMESPACES).each do |xml_tag|
            xml_tag.content = case xml_tag.content
                              when /(\d{5})-(\d{4})/
                                xml_tag.content.match(/(\d{5})-(\d{4})/)[1]
                              when /(\d{5}).+/
                                xml_tag.content.match(/(\d{5}).+/)[1]
                              else
                                xml_tag.content
                              end
          end
        end
      end
    end
  end
end
