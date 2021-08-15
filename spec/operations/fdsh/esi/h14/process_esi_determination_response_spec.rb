# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe Fdsh::Esi::H14::ProcessEsiDeterminationResponse do

  let(:file) do
    loc = File.join(Rails.root, "spec", "reference", "xml", "esi", "MaxResponse.xml")
    File.expand_path(loc)
  end

  let(:xml) {Nokogiri::XML(File.open(file))}

  before do
    @result = described_class.new.call(xml)
  end

  it "is successful" do
    expect(@result.success?).to be_truthy
  end

  it "result to be an Attestation object" do
    expect(@result.value!).to be_a AcaEntities::Fdsh::Esi::H14::ESIMECResponse
  end
end