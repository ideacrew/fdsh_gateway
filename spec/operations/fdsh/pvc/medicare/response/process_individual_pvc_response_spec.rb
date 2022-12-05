# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

RSpec.describe Fdsh::Pvc::Medicare::Response::ProcessIndividualPvcResponse, dbclean: :after_each do

  describe "ProcessIndividualPvcResponse" do
    let(:individual_response) do
      {
        :PersonSSNIdentification => "011789802",
        :Insurances => [{ :InsuranceEffectiveDate => Date.new(2019, 1, 1) }],
        :OrganizationResponseCode => "0000",
        :OrganizationResponseCodeText => "Business Transaction Successful"
      }
    end

    applications = [TEST_APPLICATION_1, TEST_APPLICATION_5].collect do |payload|
      AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload).value!
    end

    before do
      create_transaction_store_request_pvc(applications)
    end

    it "should success" do
      result = described_class.new.call(individual_response)
      expect(result).to be_success
    end
  end

  describe "when applicant doesn't have medicare beenefits" do
    context "when application start date is matched with response date" do
      let(:individual_response_params) do
        { :PersonSSNIdentification => "011789802",
          :Insurances => [
            { :InsuranceEffectiveDate => Date.today }
          ],
          :OrganizationResponseCode => "0000",
          :OrganizationResponseCodeText => "Business Transaction Successful" }
      end

      let(:individual_response) { AcaEntities::Fdsh::Pvc::Medicare::IndividualResponse.new(individual_response_params) }
      let(:applicant) {double}
      let(:application_effective_on) { Date.today }

      before do
        allow(applicant).to receive(:health_benefits_for).with('medicare').and_return(false)
      end

      it 'should return outstanding' do
        result = described_class.new.send(:determine_medicare_status, individual_response, applicant, application_effective_on)
        expect(result).to eq 'outstanding'
      end
    end

    context "when application start date is less than response date" do
      let(:individual_response_params) do
        { :PersonSSNIdentification => "011789802",
          :Insurances => [
            { :InsuranceEffectiveDate => Date.today + 10.days }
          ],
          :OrganizationResponseCode => "0000",
          :OrganizationResponseCodeText => "Business Transaction Successful" }
      end

      let(:individual_response) { AcaEntities::Fdsh::Pvc::Medicare::IndividualResponse.new(individual_response_params) }
      let(:applicant) {double}
      let(:application_effective_on) { Date.today }

      before do
        allow(applicant).to receive(:health_benefits_for).with('medicare').and_return(false)
      end

      it 'should return attested' do
        result = described_class.new.send(:determine_medicare_status, individual_response, applicant, application_effective_on)
        expect(result).to eq 'attested'
      end
    end

    context "when application start date is greater than response start date and less than response end date" do
      let(:individual_response_params) do
        { :PersonSSNIdentification => "011789802",
          :Insurances => [
            { :InsuranceEffectiveDate => Date.today - 10.days,
              :InsuranceEndDate => Date.today + 10.days }
          ],
          :OrganizationResponseCode => "0000",
          :OrganizationResponseCodeText => "Business Transaction Successful" }
      end

      let(:individual_response) { AcaEntities::Fdsh::Pvc::Medicare::IndividualResponse.new(individual_response_params) }
      let(:applicant) {double}
      let(:application_effective_on) { Date.today }

      before do
        allow(applicant).to receive(:health_benefits_for).with('medicare').and_return(false)
      end

      it 'should return attested' do
        result = described_class.new.send(:determine_medicare_status, individual_response, applicant, application_effective_on)
        expect(result).to eq 'outstanding'
      end
    end

    context "when application start date is greater than response start date and less than response end date" do
      let(:individual_response_params) do
        { :PersonSSNIdentification => "011789802",
          :Insurances => [
            { :InsuranceEffectiveDate => Date.today - 10.days,
              :InsuranceEndDate => Date.today - 2.days }
          ],
          :OrganizationResponseCode => "0000",
          :OrganizationResponseCodeText => "Business Transaction Successful" }
      end

      let(:individual_response) { AcaEntities::Fdsh::Pvc::Medicare::IndividualResponse.new(individual_response_params) }
      let(:applicant) {double}
      let(:application_effective_on) { Date.today }

      before do
        allow(applicant).to receive(:health_benefits_for).with('medicare').and_return(false)
      end

      it 'should return attested' do
        result = described_class.new.send(:determine_medicare_status, individual_response, applicant, application_effective_on)
        expect(result).to eq 'attested'
      end
    end
  end

  describe "when applicant have medicare beenefits" do
    context "when application start date is matched with response date" do
      let(:individual_response_params) do
        { :PersonSSNIdentification => "011789802",
          :Insurances => [
            { :InsuranceEffectiveDate => Date.today }
          ],
          :OrganizationResponseCode => "0000",
          :OrganizationResponseCodeText => "Business Transaction Successful" }
      end

      let(:individual_response) { AcaEntities::Fdsh::Pvc::Medicare::IndividualResponse.new(individual_response_params) }
      let(:applicant) {double}
      let(:application_effective_on) { Date.today }

      before do
        allow(applicant).to receive(:health_benefits_for).with('medicare').and_return(true)
      end

      it 'should return outstanding' do
        result = described_class.new.send(:determine_medicare_status, individual_response, applicant, application_effective_on)
        expect(result).to eq 'attested'
      end
    end

    context "when application start date is less than response date" do
      let(:individual_response_params) do
        { :PersonSSNIdentification => "011789802",
          :Insurances => [
            { :InsuranceEffectiveDate => Date.today + 10.days }
          ],
          :OrganizationResponseCode => "0000",
          :OrganizationResponseCodeText => "Business Transaction Successful" }
      end

      let(:individual_response) { AcaEntities::Fdsh::Pvc::Medicare::IndividualResponse.new(individual_response_params) }
      let(:applicant) {double}
      let(:application_effective_on) { Date.today }

      before do
        allow(applicant).to receive(:health_benefits_for).with('medicare').and_return(true)
      end

      it 'should return attested' do
        result = described_class.new.send(:determine_medicare_status, individual_response, applicant, application_effective_on)
        expect(result).to eq 'attested'
      end
    end

    context "when application start date is greater than response start date and less than response end date" do
      let(:individual_response_params) do
        { :PersonSSNIdentification => "011789802",
          :Insurances => [
            { :InsuranceEffectiveDate => Date.today - 10.days,
              :InsuranceEndDate => Date.today + 10.days }
          ],
          :OrganizationResponseCode => "0000",
          :OrganizationResponseCodeText => "Business Transaction Successful" }
      end

      let(:individual_response) { AcaEntities::Fdsh::Pvc::Medicare::IndividualResponse.new(individual_response_params) }
      let(:applicant) {double}
      let(:application_effective_on) { Date.today }

      before do
        allow(applicant).to receive(:health_benefits_for).with('medicare').and_return(true)
      end

      it 'should return attested' do
        result = described_class.new.send(:determine_medicare_status, individual_response, applicant, application_effective_on)
        expect(result).to eq 'attested'
      end
    end

    context "when application start date is greater than response start date and less than response end date" do
      let(:individual_response_params) do
        { :PersonSSNIdentification => "011789802",
          :Insurances => [
            { :InsuranceEffectiveDate => Date.today - 10.days,
              :InsuranceEndDate => Date.today - 2.days }
          ],
          :OrganizationResponseCode => "0000",
          :OrganizationResponseCodeText => "Business Transaction Successful" }
      end

      let(:individual_response) { AcaEntities::Fdsh::Pvc::Medicare::IndividualResponse.new(individual_response_params) }
      let(:applicant) {double}
      let(:application_effective_on) { Date.today }

      before do
        allow(applicant).to receive(:health_benefits_for).with('medicare').and_return(true)
      end

      it 'should return attested' do
        result = described_class.new.send(:determine_medicare_status, individual_response, applicant, application_effective_on)
        expect(result).to eq 'attested'
      end
    end
  end
end