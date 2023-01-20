# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

RSpec.describe Fdsh::Pvc::Medicare::Request::BuildPvcMdcrDeterminationRequest do

  before :all do
    DatabaseCleaner.clean
  end

  let!(:params_manifest) {{ :assistance_year => 1000, :type => "pvc_manifest_type" }}
  let!(:params_request) {{ :subject_id => "1000", :command => "medicare", :request_payload => APPLICANT_1.to_json }}

  subject do
    result = AcaEntities::MagiMedicaid::Contracts::ApplicantContract.new.call(APPLICANT_1)
    applicant_entity = AcaEntities::MagiMedicaid::Applicant.new(result.to_h)
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