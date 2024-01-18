# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::Vlp::Rx142::CloseCase::ProcessCloseCaseResponse do

  context 'without errors' do
    let(:file) do
      loc = File.join(Rails.root, "spec", "reference", "xml", "vlp", "rx142", "close_case", "CloseCaseResponse.xml")
      File.expand_path(loc)
    end

    let(:xml_content) { File.open(file) }
    let(:xml_response) do
      Faraday::Response.new(status: 200, response_body: xml_content)
    end

    before do
      @result = described_class.new.call(xml_response)
    end

    it "is successful" do
      expect(@result.success?).to be_truthy
    end

    it "result to be an Attestation object" do
      expect(@result.value!).to be_a AcaEntities::Fdsh::Vlp::Rx142::CloseCase::CloseCaseResponse
    end
  end

  context 'with errors' do
    let(:file) do
      loc = File.join(Rails.root, "spec", "reference", "xml", "vlp", "rx142", "close_case", "CloseCaseErrorResponse.xml")
      File.expand_path(loc)
    end

    let(:xml_content) { File.open(file) }
    let(:xml_response) do
      Faraday::Response.new(status: 200, response_body: xml_content)
    end

    before do
      @result = described_class.new.call(xml_response)
    end

    it "is successful" do
      expect(@result.success?).to be_truthy
    end

    it "result to be an Attestation object" do
      expect(@result.value!).to be_a AcaEntities::Fdsh::Vlp::Rx142::CloseCase::CloseCaseResponse
    end
  end
end