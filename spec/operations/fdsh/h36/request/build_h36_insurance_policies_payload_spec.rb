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
  end
end
