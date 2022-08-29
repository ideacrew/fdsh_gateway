# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

RSpec.describe Fdsh::Pvc::Medicare::Response::ParsePvcMedicareResponse do

  after :all do
    DatabaseCleaner.clean
  end

  let(:file_path) { "#{Rails.root}/spec/reference/pvc_medicare_response.zip" }

  applications = [TEST_APPLICATION_1, TEST_APPLICATION_2, TEST_APPLICATION_3, TEST_APPLICATION_4, TEST_APPLICATION_5,
                  TEST_APPLICATION_6, TEST_APPLICATION_7, TEST_APPLICATION_8, TEST_APPLICATION_9, TEST_APPLICATION_10,
                  TEST_APPLICATION_11, TEST_APPLICATION_12, TEST_APPLICATION_13, TEST_APPLICATION_14,
                  TEST_APPLICATION_15, TEST_APPLICATION_16, TEST_APPLICATION_17].collect do |payload|
    AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload).value!
  end

  subject do
    create_transaction_store_request(applications)
    described_class.new.call(file_path)
  end

  it "success" do
    expect(subject.success?).to be_truthy
  end
end