# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

RSpec.describe Fdsh::Pvc::Medicare::Request::BuildPvcMdcrDeterminationRequest do

  before :all do
    DatabaseCleaner.clean
  end

  # applications = [TEST_APPLICATION_1, TEST_APPLICATION_2, TEST_APPLICATION_3, TEST_APPLICATION_4, TEST_APPLICATION_5,
  #                 TEST_APPLICATION_6, TEST_APPLICATION_7, TEST_APPLICATION_8, TEST_APPLICATION_9, TEST_APPLICATION_10,
  #                 TEST_APPLICATION_11, TEST_APPLICATION_12, TEST_APPLICATION_13, TEST_APPLICATION_14,
  #                 TEST_APPLICATION_15, TEST_APPLICATION_16, TEST_APPLICATION_17].collect do |payload|
  #   AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload).value!
  # end

  let!(:params_manifest) {{ :assistance_year => 1000, :type => "pvc_manifest_type" }}
  let!(:params_request) {{ :subject_id => "1000", :command => "medicare", :request_payload => APPLICANT_1.to_json }}

  subject do
    result = AcaEntities::MagiMedicaid::Contracts::ApplicantContract.new.call(APPLICANT_1)
    applicant_entity = AcaEntities::MagiMedicaid::Applicant.new(result.to_h)
    # applicant = AcaEntities::MagiMedicaid::Applicant.new(APPLICANT_1)
    request_entities = ::AcaEntities::Fdsh::Pvc::Medicare::Operations::BuildMedicareRequest.new.call(applicant_entity, 1000).value!
    individual_requests = { IndividualRequests: [request_entities] }
    result = AcaEntities::Fdsh::Pvc::Medicare::EesDshBatchRequestDataContract.new.call(individual_requests)
    data = AcaEntities::Fdsh::Pvc::Medicare::EesDshBatchRequestData.new(result.to_h)

    described_class.new.call(data)
  end

  context 'success' do
    it 'should return a success monad' do
      expect(subject.success?).to be_truthy
    end

    it 'should return an string containing the xml request' do
      result = subject.value!
      expect(result).to be_a(String)
      expect(result).to include("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
      expect(result).to include("1000-12-31")
      expect(result).to include("1000-01-01")
    end
  end
end