# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H41::Transmissions::Find do
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
          status: status,
          transmission_type: transmission_type
        }
      end

      context 'with an original open H41 transmission' do
        let(:status) { :open }
        let(:transmission_type) { :original }
        let!(:h41_original_transmission) { FactoryBot.create(:h41_original_transmission) }

        it 'returns the existing open H41 transmission' do
          expect(::H41::Transmissions::Outbound::OriginalTransmission.open.count).to eq(1)
          subject
          expect(::H41::Transmissions::Outbound::OriginalTransmission.open.count).to eq(1)
        end
      end

      context 'with more than 1 original open H41 transmission' do
        let(:status) { :open }
        let(:transmission_type) { :original }
        let!(:h41_original_transmission1) { FactoryBot.create(:h41_original_transmission) }
        let!(:h41_original_transmission2) { FactoryBot.create(:h41_original_transmission) }

        context 'with argument :latest set to true' do
          let(:input_params) do
            {
              latest: true,
              reporting_year: Date.today.year,
              status: status,
              transmission_type: transmission_type
            }
          end

          it 'returns the latest existing open H41 transmission' do
            expect(subject.success).to eq(h41_original_transmission2)
          end
        end

        context 'without argument :latest' do
          it 'returns the first existing open H41 transmission' do
            expect(subject.success).to eq(h41_original_transmission1)
          end
        end
      end

      context 'with an corrected open H41 transmission' do
        let(:status) { :open }
        let(:transmission_type) { :corrected }
        let!(:h41_corrected_transmission) { FactoryBot.create(:h41_corrected_transmission) }

        it 'returns the existing open H41 transmission' do
          expect(::H41::Transmissions::Outbound::CorrectedTransmission.open.count).to eq(1)
          subject
          expect(::H41::Transmissions::Outbound::CorrectedTransmission.open.count).to eq(1)
        end
      end

      context 'with an void transmitted H41 transmission' do
        let(:status) { :transmitted }
        let(:transmission_type) { :void }
        let!(:h41_void_transmission) { FactoryBot.create(:h41_void_transmission, status: :transmitted) }

        it 'returns the existing open H41 transmission' do
          expect(::H41::Transmissions::Outbound::VoidTransmission.transmitted.count).to eq(1)
          subject
          expect(::H41::Transmissions::Outbound::VoidTransmission.transmitted.count).to eq(1)
        end
      end
    end

    context 'with invalid input params' do
      context 'bad input transmission_type' do
        let(:input_params) do
          {
            reporting_year: Date.today.year,
            status: :open,
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
            status: :open,
            transmission_type: :original
          }
        end

        it 'returns failure with errors' do
          expect(subject.failure).to eq(
            'Invalid reporting_year: test. Must be an integer.'
          )
        end
      end

      context 'bad input status' do
        let(:input_params) do
          {
            reporting_year: Date.today.year,
            status: :test,
            transmission_type: :original
          }
        end

        it 'returns failure with errors' do
          expect(subject.failure).to eq(
            'Invalid status: test. Must be one of [:open, :transmitted].'
          )
        end
      end

      context 'without open transactions' do
        let(:input_params) do
          {
            reporting_year: Date.today.year,
            status: :open,
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
