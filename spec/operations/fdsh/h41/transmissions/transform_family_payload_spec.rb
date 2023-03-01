# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response3'

RSpec.describe Fdsh::H41::Transmissions::TransformFamilyPayload do
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
        expect(result.failure).to eq('family_hbx_id required')
      end
    end

    context 'bad report_type' do
      let(:input_params) do
        {
          family_hbx_id: family_hash[:hbx_id],
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

  context '.transform_family_payload' do
    let(:correlation_id) { 'ae321f' }
    let(:contract_holder_id) { '25458' }
    let(:family_hbx_id) { '100049' }
    let(:posted_family) do
      H41::InsurancePolicies::PostedFamily.create(
        correlation_id: correlation_id,
        contract_holder_id: contract_holder_id,
        family_hbx_id: family_hbx_id
      )
    end

    let!(:insurance_polices) do
      create_list(:h41_insurance_policy, 20, :with_aptc_csr_tax_households,
                  transmission: open_transmission,
                  posted_family: posted_family)
    end

    let!(:aptc_csr_tax_household_id_1) do
      insurance_polices.first.aptc_csr_tax_households.first.hbx_assigned_id
    end

    let(:family_cv) { family_hash }

    let(:input_params) do
      {
        family_hbx_id: family_hbx_id,
        subject_hbx_ids: insurance_polices.flat_map(&:aptc_csr_tax_households).pluck(:hbx_assigned_id),
        reporting_year: Date.today.year,
        report_type: :corrected
      }
    end

    let!(:open_transmission) { FactoryBot.create(:h41_corrected_transmission) }

    it 'should transform 1095a payload successfully' do
      open_transmission.transactions.update_all(status: :transmitted)
      open_transmission.reload
      posted_family.update!(family_cv: family_cv.to_json)
      AcaEntities::Families::Family.new(family_hash)
      @result = subject.call(input_params)
      open_transmission.reload
      expect(@result.success?).to be_truthy
      family_entity = AcaEntities::Families::Family.new(@result.success)
      insurance_policy = family_entity.households.first.insurance_agreements.first.insurance_policies.first
      expect(insurance_policy.aptc_csr_tax_households.first.corrected).to eq true
    end
  end
end