# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response3'

RSpec.describe Fdsh::H36::Request::BuildH36Xml do
  include_context "family response"

  before :each do
    DatabaseCleaner.clean
  end

  let(:assistance_year) do
    Date.today.year
  end

  let!(:transmission) do
    create(:month_of_year_transmission, reporting_year: assistance_year)
  end

  let!(:irs_group) do
    create(:h36_irs_group, assistance_year: assistance_year, family_cv: family_hash.to_json)
  end

  let!(:transaction) do
    create(:transmittable_transaction, transmit_action: :transmit,
                                       started_at: Time.now, transactable: irs_group,
                                       transmission: transmission)
  end

  let(:family) { AcaEntities::Families::Family.new(family_hash) }
  let(:household) { family.households.first }
  let(:agreement) { household.insurance_agreements.first }
  let(:insurance_policy) { agreement.insurance_policies.first }
  let(:tax_household) { insurace_policy.aptc_csr_tax_households.first }

  let(:params) do
    {
      transaction_id: transaction._id,
      transmission_id: transmission.id,
      assistance_year: assistance_year,
      month_of_year: Date.today.month
    }
  end

  context "invalid_params" do
    it "should return failure if irs_group_correlation_id is blank" do
      result = ::Fdsh::H36::Request::BuildH36Xml.new.call({})
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(["transaction_id required", "transmission_id required",
                                    "assistance_year required", "month_of_year required"])
    end

    it "should return failure if assistance_year is blank" do
      result = ::Fdsh::H36::Request::BuildH36Xml.new.call({ transaction_id: transaction._id })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(["transmission_id required", "assistance_year required", "month_of_year required"])
    end

    it "should return failure if month_of_year is blank" do
      result = ::Fdsh::H36::Request::BuildH36Xml.new.call({ transaction_id: transaction._id,
                                                            transmission_id: transmission.id,
                                                            assistance_year: assistance_year })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(["month_of_year required"])
    end
  end

  context "valid_params" do
    it "should successfully build an xml and persist on irs_group monthly_activity" do
      expect(transmission.status).to eq :open
      result = Fdsh::H36::Request::BuildH36Xml.new.call(params)
      expect(result.success?).to be_truthy
      irs_group.reload
      transmission.reload
      expect(irs_group.transaction_xml).to be_present
      expect(transmission.status).to eq :pending
    end
  end
end
