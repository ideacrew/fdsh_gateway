# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response3'

RSpec.describe Fdsh::H36::Request::BuildH36InsurancePoliciesPayload do
  include_context "family response"

  before :each do
    DatabaseCleaner.clean
  end

  let(:assistance_year) do
    Date.today.year
  end

  let!(:max_month) do
    Date.today.month
  end

  let(:family) { AcaEntities::Families::Family.new(family_hash) }

  context "invalid_params" do
    it "should return failure if params are empty" do
      result = ::Fdsh::H36::Request::BuildH36InsurancePoliciesPayload.new.call({})
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(["Please pass in policies", "Please pass in max_month"])
    end
  end

  context "valid_params" do
    it "should return success" do
      agreement = family.households.first.insurance_agreements.first
      insurance_policies = agreement.insurance_policies
      params = {
        insurance_policies: insurance_policies,
        max_month: max_month
      }
      result = ::Fdsh::H36::Request::BuildH36InsurancePoliciesPayload.new.call(params)
      expect(result.success?).to be_truthy
      expect(result.success.first.keys).to include(:InsuranceCoverages)
    end

    context "carrier name mapping" do
      context "when provider name exists in the mapping" do
        let(:provider_title) { "Taro Health" }

        it "returns the mapped value" do
          agreement = family.households.first.insurance_agreements.first
          insurance_policies = agreement.insurance_policies
          params = {
            insurance_policies: insurance_policies,
            max_month: max_month
          }

          result = ::Fdsh::H36::Request::BuildH36InsurancePoliciesPayload.new.call(params)
          issuer_name = result.success[0][:InsuranceCoverages][0][:IssuerNm]
          expect(issuer_name).to eq("Taro Health Plan of Maine Inc")
        end
      end

      context "when provider name does not exist in the mapping" do
        let(:provider_title) { "Anthem Health" }

        it "returns the provided value is" do
          agreement = family.households.first.insurance_agreements.first
          insurance_policies = agreement.insurance_policies
          params = {
            insurance_policies: insurance_policies,
            max_month: max_month
          }

          result = ::Fdsh::H36::Request::BuildH36InsurancePoliciesPayload.new.call(params)
          issuer_name = result.success[0][:InsuranceCoverages][0][:IssuerNm]
          expect(issuer_name).to eq(provider_title)
        end
      end
    end
  end
end
