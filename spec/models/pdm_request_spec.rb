require 'rails_helper'

RSpec.describe PdmRequest, type: :model do
  before :all do
    DatabaseCleaner.clean
  end

  let!(:valid_params) {{ :subject_id => "abc", :command => "something" }}

  context 'valid params' do
    before do
      @manifest = PdmManifest.new({:assistance_year => 1000, :type => "something" })
      @manifest.save!

      @request = described_class.new(valid_params)
      @manifest.pdm_requests << @request
      @request.save!
    end

    it 'should be findable' do
      # expect(described_class.find(@request)).to be_a(PdmRequest)
      # obj = @manifest.pdm_requests.first
      # binding.irb
      # expect(obj).to be_a(PdmRequest)
      result = @manifest.pdm_requests.find(@request)
      expect(result).to be_a(PdmRequest)
    end
  end


end
