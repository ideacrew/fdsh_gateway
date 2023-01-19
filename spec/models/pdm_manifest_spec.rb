# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PdmManifest, type: :model do
  before :all do
    DatabaseCleaner.clean
  end

  let!(:valid_params) {{ :assistance_year => 1000, :type => "something" }}

  context 'valid params' do
    before do
      @manifest = described_class.new(valid_params)
      @manifest.save!
    end

    it 'should be findable' do
      expect(described_class.find(@manifest.id)).to be_a(PdmManifest)
    end
  end

end
