# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::Transmissions::XmlSanitizer do
  subject { described_class.new }

  after :each do
    DatabaseCleaner.clean
  end

  context 'with invalid input params' do
    context 'bad report_type' do
      let(:input_params) do
        {
          xml_string: nil
        }
      end

      it 'returns failure with errors' do
        result = subject.call(input_params)
        expect(result.failure).to eq(
          'xml string expected'
        )
      end
    end
  end

  describe '.santize' do

    context 'for original transmission' do
      let(:input_params) do
        {
          xml_string: transaction_xml
        }
      end

      let(:transaction_xml) do
        File.read(Rails.root.join("spec/test_payloads/h41/sanitizer_input.xml").to_s)
      end

      before do
        @result = subject.call(input_params)
      end

      it 'should sanitize xml successfully' do
        expect(@result.success?).to be_truthy
      end

      it 'should create new open transmission' do
        xml_doc = Nokogiri::XML(@result.success)
        xml_doc.xpath('//batchreq:Form1095ATransmissionUpstream').each do |node|
          node.xpath('//airty20a:Form1095AUpstreamDetail').each do |upstream_detail|

            upstream_detail.xpath("//irs:SSN").each do |ssn_node|
              expect(ssn_node.content).not_to include('-')
            end

            upstream_detail.xpath("//airty20a:PersonLastNm").each do |name_node|
              expect(name_node.content.length).to be <= 20
            end

            upstream_detail.xpath("//airty20a:AddressLine1Txt").each do |address_1|
              expect(address_1.content.length).to be <= 35
            end

            address_lines_1 = upstream_detail.xpath("//airty20a:AddressLine1Txt").collect(&:content)
            expect(address_lines_1).to include("TEST address 1 Line")

            address_lines_2 = upstream_detail.xpath("//airty20a:AddressLine2Txt").collect(&:content)
            expect(address_lines_2).to include("1")

            zip_codes = upstream_detail.xpath("//irs:USZIPCd").collect(&:content)
            expect(zip_codes).to include('04543')
          end
        end
      end
    end
  end
end
