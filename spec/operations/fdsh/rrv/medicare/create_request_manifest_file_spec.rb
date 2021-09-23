# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

RSpec.describe Fdsh::Rrv::Medicare::CreateRequestManifestFile do

  before :all do
    DatabaseCleaner.clean
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

  it "success" do
    expect(subject.success?).to be_truthy
  end
end