# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H36::Transmissions::XmlSanitizer do
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

    context 'for h36 transmission' do
      let(:input_params) do
        {
          xml_string: transaction_xml
        }
      end

      let(:transaction_xml) do
        File.open(Rails.root.join("spec/test_payloads/h36/sanitizer_input.xml").to_s).read
      end

      before do
        @result = subject.call(input_params)
      end

      it 'should sanitize xml successfully' do
        expect(@result.success?).to be_truthy
      end

      it 'should create new open transmission' do
        xml_doc = Nokogiri::XML(@result.success)
        xml_doc.xpath('//irs:IRSHouseholdGrp').each do |node|
          node.xpath("//irs:SSN").each do |ssn_node|
            expect(ssn_node.content).not_to include('-')
          end

          node.xpath("//irs:PersonFirstName").each do |name_node|
            expect(name_node.content.length).to be <= 20
          end

          node.xpath("//irs:AddressLine1Txt").each do |name_node|
            expect(name_node.content.length).to be <= 35
          end

          address_lines_1 = node.xpath("//irs:AddressLine1Txt").collect(&:content)
          expect(address_lines_1).to include("test me payload address 1 test agai")

          address_lines_2 = node.xpath("//irs:AddressLine2Txt").collect(&:content)
          expect(address_lines_2).to include("test")

          zip_codes = node.xpath("//irs:USZIPCd").collect(&:content)
          expect(zip_codes).to include('04472')
        end
      end
    end
  end
end
