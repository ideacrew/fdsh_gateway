# frozen_string_literal: true

require 'rails_helper'

RSpec.describe H41::InsurancePolicies::InsurancePolicy, type: :model, dbclean: :before_each do
  before :all do
    DatabaseCleaner.clean
  end

  let(:policy_hbx_id) { '21212424' }
  let(:assistance_year) { Date.today.year - 1.year }

  let(:correlation_id) { 'ae321f' }
  let(:contract_holder_id) { '25458' }
  let(:family_cv) { 'family: {}' }
  let(:posted_family) do
    H41::InsurancePolicies::PostedFamily.new(
      correlation_id: correlation_id,
      contract_holder_id: contract_holder_id,
      family_cv: family_cv
    )
  end

  let(:transaction_xml) { '<xml>hello world</xml>' }
  let(:aptc_csr_tax_household_1) do
    H41::InsurancePolicies::AptcCsrTaxHousehold.new(tax_household_id: '5454555', transaction_xml: transaction_xml)
  end
  let(:aptc_csr_tax_household_2) do
    H41::InsurancePolicies::AptcCsrTaxHousehold.new(tax_household_id: '6655644', transaction_xml: transaction_xml)
  end
  let(:aptc_csr_tax_household_3) do
    H41::InsurancePolicies::AptcCsrTaxHousehold.new(tax_household_id: '6655644', transaction_xml: transaction_xml)
  end
  let(:aptc_csr_tax_households) { [aptc_csr_tax_household_1, aptc_csr_tax_household_2, aptc_csr_tax_household_3] }

  let(:required_params) do
    {
      policy_hbx_id: policy_hbx_id,
      assistance_year: assistance_year,
      posted_family: posted_family,
      aptc_csr_tax_households: aptc_csr_tax_households
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
