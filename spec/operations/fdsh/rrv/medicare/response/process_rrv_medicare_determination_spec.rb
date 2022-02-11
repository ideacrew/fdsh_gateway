# frozen_string_literal: true

RSpec.describe Fdsh::Rrv::Medicare::Response::ProcessRrvMedicareDetermination, dbclean: :after_each do
  describe "ProcessRrvMedicareDetermination" do
    let(:mdcr_payload) do
      { :IndividualResponses =>
        [{ :PersonSSNIdentification => "011789802",
           :Insurances => [{ :InsuranceEffectiveDate => Date.new(2019, 1, 1) }],
           :OrganizationResponseCode => "0000",
           :OrganizationResponseCodeText => "Business Transaction Successful" },
         { :PersonSSNIdentification => "007643003",
           :Insurances =>
           [{ :InsuranceEffectiveDate => Date.new(2022, 12, 1),
              :InsuranceEndDate => Date.new(2022, 12, 31) }],
           :OrganizationResponseCode => "0000",
           :OrganizationResponseCodeText => "Business Transaction Successful" }] }
    end

    let(:medicare_response) { AcaEntities::Fdsh::Rrv::Medicare::EesDshBatchResponseData.new(mdcr_payload) }

    it "should success" do
      result = described_class.new.call(medicare_response)
      expect(result).to be_success
    end
  end
end