# frozen_string_literal: true

require 'rails_helper'
# require_relative '../shared_setup'

RSpec.describe Pdm::Manifest::FindOrCreate do
  before :all do
    DatabaseCleaner.clean
  end

  context 'Operation is called without params' do
    let(:errors) { { :assistance_year => ["is missing"], :type=> ["is missing"] } }
    it 'should fail validation' do
      expect(described_class.new.call({}).success?).to be_falsey
      expect(described_class.new.call({}).failure.errors.to_h).to eq errors
    end
  end

  context 'Operation is called using a year and type with no matching database record' do
    let(:params) {{ :assistance_year => 1000, :type=> "something" }}
    let(:result) { described_class.new.call(params) }

    before do
      expect(PdmManifest.count).to eq 0
    end

    it 'should create a new Transaction record' do
      expect(result.success?).to eq true
      expect(PdmManifest.first.type).to eq 'something'
    end
  end

end