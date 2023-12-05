# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response'

RSpec.describe Fdsh::H41::Request::Build1095aPayload do
  subject { described_class.new.call(input_params) }

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
      agreement: agreement,
      insurance_policy: insurance_policy,
      tax_household: insurance_policy.aptc_csr_tax_households.first,
      transaction_type: transaction_type,
      record_sequence_num: record_sequence_num
    }
  end

  context 'with valid params' do
    let(:input_params) { params }

    context 'for corrected transaction_type' do
      let(:transaction_type) { :corrected }
      let(:record_sequence_num) { 'batch_id|file_id|record_id' }

      it 'includes element CorrectedInd with value 1' do
        expect(subject.success[:CorrectedInd]).to eq('1')
        expect(subject.success[:VoidInd]).to eq('0')
      end

      it 'includes element CorrectedRecordSequenceNum with record_sequence_num' do
        expect(subject.success).to have_key(:CorrectedRecordSequenceNum)
        expect(subject.success[:CorrectedRecordSequenceNum]).to eq(record_sequence_num)
        expect(subject.success).not_to have_key(:VoidedRecordSequenceNum)
      end
    end

    context "carrier name mapping" do
      context "when provider name exists in the mapping" do
        let(:provider_title) { "Taro Health" }
        let(:transaction_type) { :corrected }
        let(:record_sequence_num) { 'batch_id|file_id|record_id' }

        it "returns the mapped value" do
          expect(subject.success[:Policy][:PolicyIssuerNm]).to eq("Taro Health Plan of Maine Inc")
        end
      end

      context "when provider name does not exist in the mapping" do
        let(:provider_title) { "Anthem Health" }
        let(:transaction_type) { :corrected }
        let(:record_sequence_num) { 'batch_id|file_id|record_id' }

        it "returns the provided value" do
          expect(subject.success[:Policy][:PolicyIssuerNm]).to eq(provider_title)
        end
      end
    end

    context 'for original transaction_type' do
      let(:transaction_type) { :original }
      let(:record_sequence_num) { nil }

      it 'includes elements CorrectedInd, VoidInd with value 0' do
        expect(subject.success[:CorrectedInd]).to eq('0')
        expect(subject.success[:VoidInd]).to eq('0')
      end

      it 'includes element CorrectedRecordSequenceNum with record_sequence_num' do
        expect(subject.success).not_to have_key(:CorrectedRecordSequenceNum)
        expect(subject.success).not_to have_key(:VoidedRecordSequenceNum)
      end
    end

    context 'for void transaction_type' do
      let(:transaction_type) { :void }
      let(:record_sequence_num) { 'batch_id|file_id|record_id' }

      it 'includes element VoidInd with value 1' do
        expect(subject.success[:CorrectedInd]).to eq('0')
        expect(subject.success[:VoidInd]).to eq('1')
      end

      it 'includes element VoidedRecordSequenceNum with record_sequence_num' do
        expect(subject.success).not_to have_key(:CorrectedRecordSequenceNum)
        expect(subject.success).to have_key(:VoidedRecordSequenceNum)
        expect(subject.success[:VoidedRecordSequenceNum]).to eq(record_sequence_num)
      end
    end
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
            'tax_household required',
            'transaction_type required'
          ]
        )
      end
    end

    context 'with missing record_sequence_num for non original transaction_type' do
      let(:transaction_type) { [:corrected, :void].sample }
      let(:record_sequence_num) { nil }
      let(:input_params) { params }

      it 'returns failure with error messages' do
        expect(subject.failure).to eq(
          ['record_sequence_num required for transaction_type']
        )
      end
    end
  end
end
