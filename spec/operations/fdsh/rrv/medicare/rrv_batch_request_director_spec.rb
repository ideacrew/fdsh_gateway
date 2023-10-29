# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

RSpec.describe Fdsh::Rrv::Medicare::RrvBatchRequestDirector do

  before :all do
    DatabaseCleaner.clean
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/rrv_outbound_files_test")
    FileUtils.rm_rf(
      "#{Rails.root}/log/rrv_batch_request_director_#{DateTime.now.strftime('%Y_%m_%d')}.log}"
    )
  end

  let(:create_application_requests) do
    (1..17).each do |index|
      Fdsh::Rrv::Medicare::Request::StoreApplicationRrvRequest.new.call({ application_hash: "TEST_APPLICATION_#{index}".constantize })
    end
  end

  before do
    create_application_requests
  end

  let(:params) do
    {
      assistance_year: 2022,
      transactions_per_file: 4,
      outbound_folder_name: 'rrv_outbound_files_test',
      batch_size: 2,
      start_date: Date.today
    }
  end

  let(:params_2) do
    {
      assistance_year: 2022,
      transactions_per_file: 4,
      outbound_folder_name: 'rrv_outbound_files_test',
      batch_size: 2,
      start_date: Date.today + 10.days
    }
  end

  it "should create batch request zip file" do
    result = described_class.new.call(params)
    expect(Transaction.count).to eq 17
    expect(result.success?).to be_truthy
    expect(result.success).to eq "rrv_outbound_files_test"
    expect(Dir[Rails.root.join("rrv_outbound_files_test/SBE00ME.DSH.RRVIN.D*.IN.zip")].count).to eq 5
  end

  it "should not pull transactions before start_date param" do
    result = described_class.new.call(params_2)
    expect(Transaction.count).to eq 17
    expect(result.success?).to be_truthy
    expect(result.success).to eq "rrv_outbound_files_test"
    expect(Dir[Rails.root.join("rrv_outbound_files_test/SBE00ME.DSH.RRVIN.D*.IN.zip")].count).to eq 0
  end

  let(:logger_file_contents) do
    File.open("#{Rails.root}/log/rrv_batch_request_director_#{DateTime.now.strftime('%Y_%m_%d')}.log", 'r').read
  end

  context 'with valid params' do
    before { subject.call(params) }

    it 'logs information' do
      expect(logger_file_contents).to include(
        '----- Process Started with values:',
        'Total transactions to process:',
        'Created outbound folder:',
        '----- Process Ended'
      )
    end
  end
end
