# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/family_response5'

RSpec.describe H41::InsurancePolicies::PostedFamily, type: :model do
  include_context 'family response with one policy coverage_start_on as feb 1'

  let(:correlation_id) { 'ae321f' }
  let(:contract_holder_id) { '25458' }
  let(:family_cv) { 'family: {}' }

  let(:policy_hbx_id) { '6655644' }
  let(:assistance_year) { Date.today.year - 1.year }

  let(:insurance_policies) do
    [
      H41::InsurancePolicies::InsurancePolicy.new(
        policy_hbx_id: policy_hbx_id,
        assistance_year: assistance_year,
        aptc_csr_tax_households: aptc_csr_tax_households
      )
    ]
  end

  let(:transaction_xml) { '<xml>hello world</xml>' }
  let(:aptc_csr_tax_households) do
    [H41::InsurancePolicies::AptcCsrTaxHousehold.new(hbx_assigned_id: '5454555', transaction_xml: transaction_xml)]
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

  let(:posted_family) { FactoryBot.create(:posted_family, family_cv: family_cv) }

  describe '#family_cv_hash' do
    context 'with family_cv' do
      let(:family_cv) { family_hash2.to_json }

      it 'returns parsed hash' do
        expect(posted_family.family_cv_hash).to be_a(Hash)
      end
    end

    context 'without family_cv' do
      let(:family_cv) { nil }

      it 'returns nil' do
        expect(posted_family.family_cv_hash).to be_nil
      end
    end
  end

  describe '#family_entity' do
    context 'with family_cv' do
      let(:family_cv) { family_hash2.to_json }

      it 'returns parsed hash' do
        expect(posted_family.family_entity).to be_a(
          ::AcaEntities::Families::Family
        )
      end
    end

    context 'without family_cv' do
      let(:family_cv) { nil }

      it 'returns nil' do
        expect(posted_family.family_entity).to be_nil
      end
    end
  end
end
