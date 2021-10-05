# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

# dummy class for creating transactions
class StoreRequest
  def store_request(applications)
    applications.each do |application|
      application.applicants.each do |applicant|
        create_or_update_transaction("request", application, applicant)
      end
    end
  end

  def create_or_update_transaction(key, value, applicant)
    activity_hash = {
      correlation_id: "rrv_mdcr_#{applicant.identifying_information.encrypted_ssn}",
      command: "Fdsh::Rrv::Medicare::BuildMedicareRequestXml",
      event_key: "rrv_mdcr_determination_requested",
      message: { "#{key}": value.to_h }
    }

    transaction_hash = { correlation_id: activity_hash[:correlation_id], magi_medicaid_application: value.to_json,
                         activity: activity_hash }
    Journal::Transactions::AddActivity.new.call(transaction_hash).value!
  end
end

RSpec.describe Fdsh::Rrv::Medicare::Response::ParseRrvMedicareResponse do

  after :all do
    DatabaseCleaner.clean
  end

  let(:file_path) { "#{Rails.root}/spec/reference/rrv_medicare_response.zip" }

  applications = [TEST_APPLICATION_1, TEST_APPLICATION_2, TEST_APPLICATION_3, TEST_APPLICATION_4, TEST_APPLICATION_5,
                  TEST_APPLICATION_6, TEST_APPLICATION_7, TEST_APPLICATION_8, TEST_APPLICATION_9, TEST_APPLICATION_10,
                  TEST_APPLICATION_11, TEST_APPLICATION_12, TEST_APPLICATION_13, TEST_APPLICATION_14,
                  TEST_APPLICATION_15, TEST_APPLICATION_16, TEST_APPLICATION_17].collect do |payload|
    AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload).value!
  end

  StoreRequest.new.store_request(applications)

  subject do
    described_class.new.call(file_path)
  end

  it "success" do
    expect(subject.success?).to be_truthy
  end
end