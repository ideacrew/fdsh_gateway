# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response3'

RSpec.describe Fdsh::H41::Transmissions::Publish1095aPayload do
  include_context "family response"

  subject { described_class.new }

  before :all do
    DatabaseCleaner.clean
  end

  after :all do
    Dir["#{Rails.root}/log/publish_1095a_payload_errors_*"].each do |file|
      File.delete(file)
    end
  end

  context 'with invalid input params' do
    context 'no transmission sent' do
      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_type: :initial
        }
      end

      it 'returns failure with errors' do
        result = subject.call(input_params)
        expect(result.failure).to eq('transmission required')
      end
    end

    context 'bad report_type' do
      let(:input_params) do
        {
          transmission: "test",
          reporting_year: Date.today.year,
          report_type: :initial
        }
      end

      it 'returns failure with errors' do
        result = subject.call(input_params)
        expect(result.failure).to eq('report_type must be one corrected, original, void')
      end
    end
  end

  describe '.publish_1095a_payload' do
    let(:correlation_id) { 'ae321f' }
    let(:contract_holder_id) { '25458' }
    let(:family_hbx_id) { '1001049' }
    let(:family_cv) { family_hash }

    let(:posted_family) do
      H41::InsurancePolicies::PostedFamily.create(
        correlation_id: correlation_id,
        contract_holder_id: contract_holder_id,
        family_cv: family_cv.to_json,
        family_hbx_id: family_hbx_id
      )
    end

    let(:aptc_csr_tax_household_1) do
      insurance_policy.aptc_csr_tax_households.create(hbx_assigned_id: '5454555', transaction_xml: transaction_xml)
    end

    let(:policy_hbx_id) { '6655644' }
    let(:assistance_year) { Date.today.year }

    let(:insurance_policy) do
      posted_family.insurance_policies.create(
        policy_hbx_id: policy_hbx_id,
        assistance_year: assistance_year,
        posted_family: posted_family
      )
    end

    let!(:insurance_polices) do
      create_list(:h41_insurance_policy, 20, :with_aptc_csr_tax_households,
                  transmission: open_transmission,
                  posted_family: posted_family)
    end

    context 'for original transmission with pending transactions' do
      let(:input_params) do
        {
          transmission: open_transmission,
          reporting_year: Date.today.year,
          report_type: :corrected
        }
      end

      let!(:open_transmission) { FactoryBot.create(:h41_corrected_transmission) }

      before do
        @result = subject.call(input_params)
      end

      it 'should publish 1095a payload successfully' do
        expect(@result.failure?).to be_truthy
        expect(@result.failure).to eq 'No valid transactions present'
      end
    end

    context 'for original transmission' do
      let!(:aptc_csr_tax_household_id_1) { "66668" }

      let(:input_params) do
        {
          transmission: open_transmission,
          reporting_year: Date.today.year,
          report_type: :corrected
        }
      end

      let!(:open_transmission) { FactoryBot.create(:h41_corrected_transmission) }

      before do
        open_transmission.transactions.update_all(status: :transmitted)
        open_transmission.reload
        @result = subject.call(input_params)
        open_transmission.reload
      end

      it 'should publish 1095a payload successfully' do
        expect(@result.success?).to be_truthy
      end
    end
  end
end