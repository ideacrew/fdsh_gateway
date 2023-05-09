# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

RSpec.describe Fdsh::Pvc::Medicare::PvcBatchRequestDirector do

  before :all do
    DatabaseCleaner.clean
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/pvc_outbound_files_test")
  end

  let(:create_application_requests) do
    (1..17).each do |index|
      Fdsh::Pvc::Medicare::Request::StoreRequest.new.call({ application_hash: "TEST_APPLICATION_#{index}".constantize })
    end
  end

  before do
    create_application_requests
  end

  let(:params) do
    {
      assistance_year: 2022,
      transactions_per_file: 4,
      outbound_folder_name: 'pvc_outbound_files_test',
      batch_size: 2
    }
  end

  subject do
    described_class.new.call(params)
  end

  it "should create batch request zip file" do
    expect(Transaction.count).to eq 17
    expect(subject.success?).to be_truthy
    expect(subject.success).to eq "#{Rails.root}/pvc_outbound_files_test"
    expect(Dir[Rails.root.join("pvc_outbound_files_test/SBE00ME.DSH.PVC1.D*.IN")].count).to eq 5
  end
end
