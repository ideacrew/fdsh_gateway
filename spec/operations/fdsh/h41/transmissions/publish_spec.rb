# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H41::Transmissions::Publish do
  subject { described_class.new }

  after :each do
    DatabaseCleaner.clean
  end

  context 'with invalid input params' do
    context 'bad report_type' do
      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_type: :initial
        }
      end

      it 'returns failure with errors' do
        result = subject.call(input_params)
        expect(result.failure).to eq(
          'report_type must be one corrected, original, void'
        )
      end
    end
  end

  describe '.publish' do
    let(:correlation_id) { 'ae321f' }
    let(:contract_holder_id) { '25458' }
    let(:family_cv) { 'family: {}' }

    let(:posted_family) do
      H41::InsurancePolicies::PostedFamily.create(
        correlation_id: correlation_id,
        contract_holder_id: contract_holder_id,
        family_cv: family_cv
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
      create_list(:h41_insurance_policy, 20, :with_aptc_csr_tax_households, transaction_xml: transaction_xml,
                                                                            transmission: open_transmission)
    end

    context 'for original transmission' do
      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_type: :original
        }
      end

      let!(:open_transmission) { FactoryBot.create(:h41_original_transmission) }
      let(:transaction_xml) { File.open(Rails.root.join("spec/test_payloads/h41/original.xml").to_s).read }

      before do
        @result = subject.call(input_params)
        open_transmission.reload
      end

      it 'should generate h41 successfully' do
        expect(@result.success?).to be_truthy
      end

      it 'should change open transmission to transmitted' do
        expect(open_transmission.status).to eq :transmitted
      end

      it 'should create new open transmission' do
        new_transmission = Transmittable::Transmission.open.first

        expect(new_transmission).not_to eq open_transmission
        expect(new_transmission.reporting_year).to eq input_params[:reporting_year]
        expect(new_transmission.class).to eq open_transmission.class
      end

      # it 'should create content and manifest files' do
      # end

      it 'should update transmission to transmitted state' do
        open_transmission.transactions.each do |transaction|
          expect(transaction.status).to eq :transmitted
          expect(transaction.transmit_action).to eq :no_transmit
        end
      end

      it 'should create transmission paths for batch id' do
        expect(open_transmission.transmission_paths.count).to eq open_transmission.transactions.count
      end
    end

    context 'for corrected' do
      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_type: :corrected
        }
      end

      let!(:open_transmission) { FactoryBot.create(:h41_corrected_transmission) }
      let(:transaction_xml) { File.open(Rails.root.join("spec/test_payloads/h41/corrected.xml").to_s).read }

      before do
        @result = subject.call(input_params)
        open_transmission.reload
      end

      it 'should generate corrected h41 successfully' do
        expect(@result.success?).to be_truthy
      end

      it 'should change open transmission to transmitted' do
        expect(open_transmission.status).to eq :transmitted
      end

      it 'should create new open transmission' do
        new_transmission = Transmittable::Transmission.open.first

        expect(new_transmission).not_to eq open_transmission
        expect(new_transmission.reporting_year).to eq input_params[:reporting_year]
        expect(new_transmission.class).to eq open_transmission.class
      end

      # it 'should create content and manifest files' do
      # end

      it 'should update transmission to transmitted state' do
        open_transmission.transactions.each do |transaction|
          expect(transaction.status).to eq :transmitted
          expect(transaction.transmit_action).to eq :no_transmit
        end
      end

      it 'should create transmission paths for batch id' do
        expect(open_transmission.transmission_paths.count).to eq open_transmission.transactions.count
      end
    end

    context 'for void' do
      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_type: :void
        }
      end

      let!(:open_transmission) { FactoryBot.create(:h41_void_transmission) }
      let(:transaction_xml) { File.open(Rails.root.join("spec/test_payloads/h41/void.xml").to_s).read }

      before do
        @result = subject.call(input_params)
        open_transmission.reload
      end

      it 'should generate void h41 successfully' do
        expect(@result.success?).to be_truthy
      end

      it 'should change open transmission to transmitted' do
        expect(open_transmission.status).to eq :transmitted
      end

      it 'should create new open transmission' do
        new_transmission = Transmittable::Transmission.open.first

        expect(new_transmission).not_to eq open_transmission
        expect(new_transmission.reporting_year).to eq input_params[:reporting_year]
        expect(new_transmission.class).to eq open_transmission.class
      end

      # it 'should create content and manifest files' do
      # end

      it 'should update transmission to transmitted state' do
        open_transmission.transactions.each do |transaction|
          expect(transaction.status).to eq :transmitted
          expect(transaction.transmit_action).to eq :no_transmit
        end
      end

      it 'should create transmission paths for batch id' do
        expect(open_transmission.transmission_paths.count).to eq open_transmission.transactions.count
      end
    end
  end
end
