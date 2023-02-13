# frozen_string_literal: true

require 'rails_helper'

RSpec.describe H41::InsurancePolicies::PostedFamily, type: :model do
  let(:correlation_id) { 'ae321f' }
  let(:contract_holder_id) { '25458' }
  let(:family_cv) { 'family: {}' }

  let(:policy_id) { '6655644' }
  let(:assistance_year) { Date.today.year - 1.year }

  let(:insurance_policies) do
    [
      H41::InsurancePolicies::InsurancePolicy.new(
        policy_id: policy_id,
        assistance_year: assistance_year,
        tax_households: tax_households
      )
    ]
  end

  let(:transaction_xml) { '<xml>hello world</xml>' }
  let(:tax_households) do
    [H41::InsurancePolicies::TaxHousehold.new(tax_household_id: '5454555', transaction_xml: transaction_xml)]
  end

  let(:required_params) do
    {
      correlation_id: correlation_id,
      contract_holder_id: contract_holder_id,
      family_cv: family_cv,
      insurance_policies: insurance_policies
    }
  end

  context 'Given all required, valid params' do
    it 'should be valid, persist and findable' do
      result = described_class.new(required_params)
      expect(described_class.all.count).to eq 0
      expect(result.valid?).to be_truthy
      expect(result.save).to be_truthy
      expect(described_class.all.count).to eq 1
      expect(described_class.find(result._id).created_at).to be_present
    end
  end
end
