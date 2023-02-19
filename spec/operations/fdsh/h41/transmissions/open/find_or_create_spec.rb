# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H41::Transmissions::Open::FindOrCreate do
  subject { described_class.new.call(input_params) }

  before :all do
    DatabaseCleaner.clean
  end

  after :each do
    DatabaseCleaner.clean
  end

  describe '#call' do
    context 'with valid input params' do
      let(:input_params) { { transmission_type: :original } }

      context 'without an open H41 transmission' do
        it 'creates an open H41 transmission' do
          expect(::H41::Transmissions::Outbound::OriginalTransmission.open.count).to be_zero
          subject
          expect(::H41::Transmissions::Outbound::OriginalTransmission.open.count).to eq(1)
        end
      end

      context 'with an open H41 transmission' do
        let!(:h41_original_transmission) { FactoryBot.create(:h41_original_transmission) }

        it 'returns the existing open H41 transmission' do
          expect(::H41::Transmissions::Outbound::OriginalTransmission.open.count).to eq(1)
          subject
          expect(::H41::Transmissions::Outbound::OriginalTransmission.open.count).to eq(1)
        end
      end
    end

    context 'with invalid input params' do
      context 'bad input transmission_type' do
        let(:input_params) { { transmission_type: :test } }

        it 'returns failure with errors' do
          expect(subject.failure).to eq(
            'Invalid transmission type: test. Must be one of [:corrected, :original, :void]'
          )
        end
      end
    end
  end
end
