# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H36::Transmissions::Create do
  subject { described_class.new.call(input_params) }

  before :all do
    DatabaseCleaner.clean
  end

  after :each do
    DatabaseCleaner.clean
  end

  describe '#call' do
    context 'with valid input params' do
      context 'without an open H36 transmission' do
        let(:input_params) { { assistance_year: Date.today.year, month_of_year: Date.today.month } }
        it 'creates an open H36 transmission' do
          expect(::H36::Transmissions::Outbound::MonthOfYearTransmission.open.count).to be_zero
          subject
          expect(::H36::Transmissions::Outbound::MonthOfYearTransmission.open.count).to eq(1)
        end
      end

      context 'with an open H36 transmission with same reporting year' do
        let(:input_params) { { assistance_year: Date.today.year, month_of_year: Date.today.month } }
        let!(:month_of_year_transmission) do
          FactoryBot.create(:month_of_year_transmission, reporting_year: Date.today.year,
                                                         month_of_year: Date.today.month)
        end

        it 'returns the existing open H36 transmission' do
          expect(::H36::Transmissions::Outbound::MonthOfYearTransmission.open.count).to eq(1)
          subject
          expect(::H36::Transmissions::Outbound::MonthOfYearTransmission.open.count).to eq(1)
        end
      end
    end

    context 'with invalid input params' do
      context 'bad input' do
        let(:input_params) { {} }

        it 'returns failure with errors' do
          expect(subject.failure).to eq('Please pass in assistance_year')
        end
      end
    end
  end
end
