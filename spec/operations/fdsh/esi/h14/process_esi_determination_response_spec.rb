# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe Fdsh::Esi::H14::ProcessEsiDeterminationResponse do

  let(:file) do
    loc = File.join(Rails.root, "spec", "reference", "xml", "esi", "MaxResponse.xml")
    File.expand_path(loc)
  end

  let(:xml) {Nokogiri::XML(File.open(file))}

  let(:params) do
    {
      correlation_id: "123456789",
      event_key: 'determine_esi_mec_eligibility'
    }
  end

  before do
    @result = described_class.new.call(xml, params)
  end

  it "is successful" do
    expect(@result.success?).to be_truthy
  end

  it "result to be an Attestation object" do
    expect(@result.value!).to be_a AcaEntities::Fdsh::Esi::H14::ESIMECResponse
  end
end

RSpec.describe Fdsh::Esi::H14::ProcessEsiDeterminationResponse do

  let(:file) do
    loc = File.join(Rails.root, "spec", "reference", "xml", "esi", "TestResponse2.xml")
    File.expand_path(loc)
  end

  let(:xml) {Nokogiri::XML(File.open(file))}

  let(:params) do
    {
      correlation_id: "123456789",
      event_key: 'determine_esi_mec_eligibility'
    }
  end

  before do
    @result = described_class.new.call(xml, params)
  end

  it "is successful" do
    expect(@result.success?).to be_truthy
  end

  it "result to be an Attestation object" do
    expect(@result.value!).to be_a AcaEntities::Fdsh::Esi::H14::ESIMECResponse
  end
end

RSpec.describe Fdsh::Esi::H14::ProcessEsiDeterminationResponse do

  let(:file) do
    loc = File.join(Rails.root, "spec", "reference", "xml", "esi", "TestResponse.xml")
    File.expand_path(loc)
  end

  let(:xml) {Nokogiri::XML(File.open(file))}

  let(:params) do
    {
      correlation_id: "123456789",
      event_key: 'determine_esi_mec_eligibility'
    }
  end

  before do
    @result = described_class.new.call(xml, params)
  end

  it "is successful" do
    expect(@result.success?).to be_truthy
  end

  it "result to be an Attestation object" do
    expect(@result.value!).to be_a AcaEntities::Fdsh::Esi::H14::ESIMECResponse
  end
end