# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response'

RSpec.describe Fdsh::H41::Request::BuildH41Xml do
  include_context "family response from enroll"

  before :all do
    DatabaseCleaner.clean
  end

  let(:family) { AcaEntities::Families::Family.new(family_hash) }
  let(:household) { family.households.first }
  let(:agreement) { household.insurance_agreements.first }
  let(:insurance_policy) { agreement.insurance_policies.first }
  let(:tax_household) { insurace_policy.aptc_csr_tax_households.first }

  let(:params) do
    {
      family: family,
      insurance_policy: insurance_policy,
      agreement: agreement,
      tax_household: insurance_policy.aptc_csr_tax_households.first
    }
  end

  let(:input_params) { params }

  subject do
    described_class.new.call(input_params)
  end

  it 'should return a success' do
    expect(subject.success?).to be_truthy
  end

  context 'with invalid params' do
    context 'with missing params' do
      let(:input_params) { {} }

      it 'returns failure with error messages' do
        expect(subject.failure).to eq(
          [
            'family required',
            'agreement required',
            'insurance_policy required',
            'tax_household required'
          ]
        )
      end
    end

    context 'with missing record_sequence_num for non original transaction_type' do
      let(:transaction_type) { [:corrected, :void].sample }
      let(:input_params) do
        params[:transaction_type] = transaction_type
        params
      end

      it 'returns failure with error messages' do
        expect(subject.failure).to eq(
          ['record_sequence_num required for transaction_type']
        )
      end
    end
  end
end
