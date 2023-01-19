# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pdm::Request::FindOrCreate do
  let!(:params_request) {{ :subject_id => "1000", :command => "medicare" }}
  let!(:params_request2) {{ :subject_id => "312312", :command => "medicare" }}
  let!(:prev_manifest) {FactoryBot.create(:pdm_manifest)}
  let!(:params_manifest) {{ :assistance_year => 1000, :type => "pvc_manifest_type" }}

  context 'with valid params but no matching manifest' do
    before :all do
      DatabaseCleaner.clean
    end

    it 'will create new objects for manifest and request' do
      @result = described_class.new.call(params_request, params_manifest)

      expect(@result.success?).to be_truthy
      expect(@result).not_to eq(prev_manifest)
    end
  end

  context 'with valid params and a matching manifest' do
    before :all do
      DatabaseCleaner.clean
    end

    it 'will not create new objects for manifest' do
      @result = described_class.new.call(params_request, { assistance_year: Date.today.year, type: 'pvc_manifest_type' })

      expect(@result.success?).to be_truthy
      expect(@result.value!.pdm_manifest).to eq(prev_manifest)
    end

    it 'will not create new objects for manifest nor request' do
      @result = described_class.new.call(params_request, { assistance_year: Date.today.year, type: 'pvc_manifest_type' })
      @result = described_class.new.call(params_request, { assistance_year: Date.today.year, type: 'pvc_manifest_type' })

      expect(@result.success?).to be_truthy
      expect(@result.value!.pdm_manifest.pdm_requests.count).to eq(1)
    end

    it 'will not create new objects for manifest but will create 2 requests' do
      @result = described_class.new.call(params_request, { assistance_year: Date.today.year, type: 'pvc_manifest_type' })
      @result = described_class.new.call(params_request2, { assistance_year: Date.today.year, type: 'pvc_manifest_type' })
      expect(@result.success?).to be_truthy
      expect(@result.value!.pdm_manifest.pdm_requests.count).to eq(2)
    end

    it 'will create new objects for manifest and request if file is generated' do
      manifest_one = described_class.new.call(params_request, { assistance_year: Date.today.year, type: 'pvc_manifest_type' })
      unwrapped_manifest = manifest_one.value!.pdm_manifest
      unwrapped_manifest.file_generated = true
      unwrapped_manifest.save
      manifest_two = described_class.new.call(params_request, { assistance_year: Date.today.year, type: 'pvc_manifest_type' })

      expect(manifest_one.value!.pdm_manifest.pdm_requests.count).not_to eq(manifest_two)
    end
  end

end