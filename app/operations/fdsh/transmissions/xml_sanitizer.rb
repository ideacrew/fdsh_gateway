# frozen_string_literal: true

module Fdsh
  module Transmissions
    # santizes xml
    class XmlSanitizer
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      NAMESPACES = {
        "xmlns:airty20a" => "urn:us:gov:treasury:irs:ext:aca:air:ty20a",
        "xmlns:irs" => "urn:us:gov:treasury:irs:common",
        "xmlns:batchreq" => "urn:us:gov:treasury:irs:msg:form1095atransmissionupstreammessage",
        "xmlns:batchresp" => "urn:us:gov:treasury:irs:msg:form1095atransmissionexchrespmessage",
        "xmlns:reqack" => "urn:us:gov:treasury:irs:msg:form1095atransmissionexchackngmessage",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
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
        xml_doc.xpath('//batchreq:Form1095ATransmissionUpstream', NAMESPACES).each do |node|
          node.xpath('//airty20a:Form1095AUpstreamDetail').each do |upstream_detail|
            sanitize_ssn(upstream_detail)
            sanitize_names(upstream_detail)
            sanitize_zipcode(upstream_detail)
          end
        end

        Success(xml_doc.to_xml(:indent => 2, :encoding => 'UTF-8'))
      end

      def sanitize_ssn(node)
        node.xpath("//irs:SSN", NAMESPACES).each do |ssn_node|
          ssn_node.content = ssn_node.content.strip.gsub("-", "")
        end
      end

      def sanitize_names(node)
        ["PersonFirstNm", "PersonMiddleNm", "PersonLastNm", "SuffixNm", "AddressLine1Txt", "AddressLine2Txt", "CityNm"].each do |ele|
          prefix = 'airty20a'
          prefix = 'irs' if ele == 'CityNm'
          node.xpath("//#{prefix}:#{ele}", NAMESPACES).each do |xml_tag|

            if xml_tag.content.match(/(-{1,2}|'|\#|"|&|<|>|\.|,|\s{2})/)
              content = xml_tag.content.gsub(/\s+/, " ").gsub(/(-{1,2}|'|\#|"|&|<|>|\.|,|\(|\)|_)/, "")
              xml_tag.content = content
            end

            if ['AddressLine1Txt', "AddressLine2Txt"].include?(ele)
              xml_tag.content = xml_tag.content.gsub(/\s+/, " ").truncate(35, :omission => '').strip
            end

            if ['PersonLastNm', 'PersonFirstNm', 'PersonMiddleNm'].include?(ele)
              xml_tag.content = xml_tag.content.gsub(/\s+/, " ").truncate(20, :omission => '').strip
            end
          end
        end
      end

      # rubocop:disable Style/CaseLikeIf
      def sanitize_zipcode(node)
        node.xpath("//irs:USZIPCd", NAMESPACES).each do |xml_tag|

          if xml_tag.content.match(/(\d{5})-(\d{4})/)
            xml_tag.content = xml_tag.content.match(/(\d{5})-(\d{4})/)[1]
          elsif xml_tag.content.match(/(\d{5}).+/)
            xml_tag.content = xml_tag.content.match(/(\d{5}).+/)[1]
          end
        end
      end
      # rubocop:enable Style/CaseLikeIf
    end
  end
end
