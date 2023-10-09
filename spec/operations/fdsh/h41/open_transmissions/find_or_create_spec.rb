# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H41::OpenTransmissions::FindOrCreate do
  include Dry::Monads[:result, :do]

  let(:result) { subject.call(input_params) }

  before :all do
    DatabaseCleaner.clean
  end

  after :each do
    DatabaseCleaner.clean
  end

  let(:corrected_transmission) { FactoryBot.create(:h41_corrected_transmission, reporting_year: reporting_year) }
  let(:original_transmission) { FactoryBot.create(:h41_original_transmission, reporting_year: reporting_year) }
  let(:void_transmission) { FactoryBot.create(:h41_void_transmission, reporting_year: reporting_year) }
  let(:input_params) { { reporting_year: reporting_year } }

  let(:failure_message) { 'Failed to create transmission.' }

  describe '#call' do
    context 'with invalid reporting_year' do
      let(:reporting_year) { 'test' }

      it 'returns failure with errors' do
        expect(result.failure).to eq(
          'Invalid reporting_year: test. Must be an integer.'
        )
      end
    end

    context 'with exisiting open transmissions' do
      let(:reporting_year) { Date.today.year.next }

      before do
        corrected_transmission
        original_transmission
        void_transmission
      end

      it 'returns success' do
        expect(result.success?).to be_truthy
      end

      it 'returns success with existing open transmissions' do
        operation_result = result.success
        expect(operation_result[:corrected]).to eq(corrected_transmission)
        expect(operation_result[:original]).to eq(original_transmission)
        expect(operation_result[:void]).to eq(void_transmission)
      end
    end

    context 'with no existing open transmissions' do
      let(:reporting_year) { Date.today.year.next }

      it 'returns success' do
        expect(result.success?).to be_truthy
      end

      it 'returns success with newly created open transmissions' do
        operation_result = result.success
        expect(operation_result[:corrected]).to be_a(::H41::Transmissions::Outbound::CorrectedTransmission)
        expect(operation_result[:original]).to be_a(::H41::Transmissions::Outbound::OriginalTransmission)
        expect(operation_result[:void]).to be_a(::H41::Transmissions::Outbound::VoidTransmission)
      end
    end

    context 'with all failed transmission generation' do
      let(:reporting_year) { Date.today.year.next }

      before do
        allow(subject).to receive(:find_or_create).and_return(Failure(failure_message))
      end

      it 'returns failure with errors' do
        expect(result.failure?).to be_truthy
      end

      it 'returns failure with errors for Original Transmission' do
        operation_result = result.failure
        expect(operation_result[:corrected]).to eq(failure_message)
        expect(operation_result[:original]).to eq(failure_message)
        expect(operation_result[:void]).to eq(failure_message)
      end
    end

    context 'with all failed transmission generation' do
      let(:reporting_year) { Date.today.year.next }

      before do
        corrected_transmission
        allow(subject).to receive(:find_or_create).and_call_original
        allow(subject).to receive(:find_or_create).with(reporting_year, :original).and_return(Failure(failure_message))
      end

      it 'returns failure with errors' do
        expect(result.failure?).to be_truthy
      end

      it 'returns failure with errors for Original Transmission' do
        operation_result = result.failure
        expect(operation_result[:corrected]).to eq(corrected_transmission)
        expect(operation_result[:original]).to eq(failure_message)
        expect(operation_result[:void]).to be_a(::H41::Transmissions::Outbound::VoidTransmission)
      end
    end
  end
end
