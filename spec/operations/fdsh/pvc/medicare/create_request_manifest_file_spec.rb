# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

RSpec.describe Fdsh::Pvc::Medicare::Request::CreateRequestManifestFile do

  before :each do
    DatabaseCleaner.clean
    @file_path = "#{Rails.root}/pvc_request_outbound"
    expect(Dir.glob("#{@file_path}/*").count).to eq(0)
  end

  after :each do
    # delete the most recent manifest (the one generated by this spec)
    manifest_from_spec = Dir[Rails.root.join("pvc_request_outbound/SBE00ME.DSH.PVC1.D*.IN")].max { |f1, f2| File.mtime(f1) <=> File.mtime(f2) }
    File.delete(manifest_from_spec)
  end

  applications = [TEST_APPLICATION_1, TEST_APPLICATION_2, TEST_APPLICATION_3, TEST_APPLICATION_4, TEST_APPLICATION_5,
                  TEST_APPLICATION_6, TEST_APPLICATION_7, TEST_APPLICATION_8, TEST_APPLICATION_9, TEST_APPLICATION_10,
                  TEST_APPLICATION_11, TEST_APPLICATION_12, TEST_APPLICATION_13, TEST_APPLICATION_14,
                  TEST_APPLICATION_15, TEST_APPLICATION_16, TEST_APPLICATION_17].collect do |payload|
    AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload).value!
  end

  subject do
    described_class.new.call(applications)
  end

  context 'success' do
    it 'should return a success monad' do
      expect(subject.success?).to be_truthy
    end

    it 'should create a zip file in the pvc_request_outbound folder' do
      subject
      expect(Dir.glob("#{@file_path}/*").count).to eq(1)
    end
  end
end