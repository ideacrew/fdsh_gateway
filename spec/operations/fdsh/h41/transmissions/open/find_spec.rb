# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H41::Transmissions::Open::Find do
  subject { described_class.new.call(input_params) }

  before :all do
    DatabaseCleaner.clean
  end

  after :each do
    DatabaseCleaner.clean
  end

  describe '#call' do
    context 'with valid input params' do
      let(:input_params) do
        {
          reporting_year: Date.today.year,
          transmission_type: :original
        }
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
        let(:input_params) do
          {
            reporting_year: Date.today.year,
            transmission_type: :test
          }
        end

        it 'returns failure with errors' do
          expect(subject.failure).to eq(
            'Invalid transmission_type: test. Must be one of [:corrected, :original, :void].'
          )
        end
      end

      context 'bad input reporting_year' do
        let(:input_params) do
          {
            reporting_year: 'test',
            transmission_type: :original
          }
        end

        it 'returns failure with errors' do
          expect(subject.failure).to eq(
            'Invalid reporting_year: test. Must be an integer.'
          )
        end
      end

      context 'without open transactions' do
        let(:input_params) do
          {
            reporting_year: Date.today.year,
            transmission_type: :original
          }
        end

        it 'returns failure with errors' do
          expect(subject.failure).to eq(
            "Unable to find OpenTransmission for type: original, reporting_year: #{Date.today.year}."
          )
        end
      end
    end
  end
end
