# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response3'

RSpec.describe Fdsh::H36::Request::BuildH36TaxHouseholdsPayload do
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
      result = ::Fdsh::H36::Request::BuildH36TaxHouseholdsPayload.new.call({})
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(["Please pass in family_entity", "Please pass in other_relevant_adult",
                                    "Please pass in policies", "Please pass in max_month"])
    end

    it "should return failure if other_relevant_adult is blank" do
      result = ::Fdsh::H36::Request::BuildH36TaxHouseholdsPayload.new.call({ family: family })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(["Please pass in other_relevant_adult", "Please pass in policies", "Please pass in max_month"])
    end

    it "should return failure if max_month is blank" do
      result = ::Fdsh::H36::Request::BuildH36TaxHouseholdsPayload.new.call({ family: family,
                                                                             other_relevant_adult: "test",
                                                                             insurance_policies: "policies" })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(["Please pass in max_month"])
    end
  end

  def fetch_other_relevant_adult(family, contract_holder)
    family.family_members.detect do |fm_member|
      fm_member.person.hbx_id == contract_holder.hbx_id
    end
  end

  context "valid params" do
    it "should return success" do
      agreement = family.households.first.insurance_agreements.first
      insurance_policies = agreement.insurance_policies
      other_relevant_adult = fetch_other_relevant_adult(family, agreement.contract_holder)
      params = {
        family: family,
        other_relevant_adult: other_relevant_adult,
        insurance_policies: insurance_policies,
        max_month: max_month
      }
      result = ::Fdsh::H36::Request::BuildH36TaxHouseholdsPayload.new.call(params)
      expect(result.success?).to be_truthy
      expect(result.success.first.keys).to include(:TaxHouseholdCoverages)
    end
  end
end