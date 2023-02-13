# frozen_string_literal: true

require 'rails_helper'

RSpec.describe H41::InsurancePolicies::AptcCsrTaxHousehold, type: :model do
  before :all do
    DatabaseCleaner.clean
  end

  it { is_expected.to belong_to(:insurance_policy) }

  let(:tax_household_id) { '525252' }
  let(:transaction_xml) { '<xml>hello world</xml>' }

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

  let(:policy_hbx_id) { '6655644' }
  let(:assistance_year) { Date.today.year - 1.year }
  let(:insurance_policy) do
    H41::InsurancePolicies::InsurancePolicy.new(
      policy_hbx_id: policy_hbx_id,
      assistance_year: assistance_year,
      posted_family: posted_family
    )
  end

  let(:required_params) do
    { insurance_policy: insurance_policy, tax_household_id: tax_household_id, transaction_xml: transaction_xml }
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

    describe 'Transmittable Behavior' do
      it 'should have an association with Transaction model' do
        expect(described_class.new).to have_many(:transactions)
      end
    end
  end
end
