# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

RSpec.describe Fdsh::Pvc::Medicare::Request::TransformApplicationToPvcMedicareRequest do

  before :all do
    DatabaseCleaner.clean
  end

  applications = [TEST_APPLICATION_1, TEST_APPLICATION_2, TEST_APPLICATION_3, TEST_APPLICATION_4, TEST_APPLICATION_5,
                  TEST_APPLICATION_6, TEST_APPLICATION_7, TEST_APPLICATION_8, TEST_APPLICATION_9, TEST_APPLICATION_10,
                  TEST_APPLICATION_11, TEST_APPLICATION_12, TEST_APPLICATION_13, TEST_APPLICATION_14,
                  TEST_APPLICATION_15, TEST_APPLICATION_16, TEST_APPLICATION_17].collect do |payload|
    AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload).value!
  end

  let(:mock_build_request_operation) do
    instance_double(::AcaEntities::Fdsh::Pvc::Medicare::Operations::BuildMedicareRequest)
  end

  let(:transactions) { Transaction.all }

  subject do
    described_class.new.call(applications)
  end

  before do
    allow(::AcaEntities::Fdsh::Pvc::Medicare::Operations::BuildMedicareRequest).to receive(:new).and_return(mock_build_request_operation)
    allow(mock_build_request_operation).to receive(:call).with(applications).and_return(Success(double))
    expect(transactions.count).to eq(0)
  end

  context 'success' do
    it 'should return success monad' do
      expect(subject.success?).to be_truthy
    end

    it 'should create a record of the transaction with request activity' do
      subject
      expect(transactions.count).to eq(1)
      expect(transactions.first.activities.count).to eq(1)
    end
  end
end