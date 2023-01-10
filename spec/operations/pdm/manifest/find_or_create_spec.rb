# frozen_string_literal: true

require 'rails_helper'
# require_relative '../shared_setup'

RSpec.describe Pdm::Manifest::FindOrCreate do
  before :all do
    DatabaseCleaner.clean
  end
  let!(:params) {{ :assistance_year => 1000, :type => "something", :file_generated => false }}

  context 'Operation is called without params' do
    let(:errors) { { :assistance_year => ["is missing"], :type => ["is missing"] } }

    before do
      described_class.new.call(params)
    end

    it 'should fail validation' do
      expect(described_class.new.call({}).success?).to be_falsey
      expect(described_class.new.call({}).failure.errors.to_h).to eq errors
    end
  end

  context 'Operation is called using a year and type with no matching database record' do

    it 'should create a new Transaction record' do
      result = described_class.new.call(params)
      expect(result.success?).to eq true
      expect(PdmManifest.first.type).to eq 'something'
    end
  end

  context 'Operation is called using a year and type with other records' do
    it 'should not create a new Transaction record' do
      first = described_class.new.call(params)
      second = described_class.new.call(params)
      expect(first).to eq second
    end

    it 'should create a new Transaction record' do
      finshed = described_class.new.call(params.merge({:file_generated => true}))
      not_finished = described_class.new.call(params)
      expect(not_finished).not_to eq finshed
    end

  end

end