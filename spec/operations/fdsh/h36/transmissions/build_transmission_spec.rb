# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H36::Transmissions::BuildTransmission do
  subject { described_class.new }

  before :each do
    FileUtils.rm_rf(Rails.root.join("h36_transmissions_#{Date.today.year}_#{Date.today.month}").to_s)
  end

  after :all do
    FileUtils.rm_rf(Rails.root.join("h36_transmissions_#{Date.today.year}_#{Date.today.month}").to_s)
  end

  after :each do
    DatabaseCleaner.clean
  end

  context 'with invalid input params' do
    context 'bad report_type' do
      let(:input_params) do
        {
          assistance_year: Date.today.year
        }
      end

      it 'returns failure with errors' do
        result = subject.call(input_params)
        expect(result.failure).to eq('month_of_year required')
      end
    end
  end

  describe '.publish' do
    let!(:transmission) do
      create(:month_of_year_transmission, reporting_year: reporting_year, month_of_year: report_month, status: :pending)
    end

    let!(:irs_group) do
      create(:h36_irs_group, assistance_year: reporting_year, transaction_xml: transaction_xml)
    end

    let!(:transaction) do
      create(:transmittable_transaction, transmit_action: :transmit,
                                         started_at: Time.now, transactable: irs_group,
                                         transmission: transmission)
    end

    let(:transaction_xml) do
      xml = File.read(Rails.root.join("spec/test_payloads/h36/sanitizer_input.xml").to_s)
      result = Fdsh::H36::Transmissions::XmlSanitizer.new.call({ xml_string: xml })
      result.success
    end

    let(:reporting_year) do
      Date.today.year
    end

    let(:report_month) do
      Date.today.month
    end

    let(:outbound_folder) do
      Rails.root.join("h36_transmissions_#{reporting_year}_#{report_month}").to_s
    end

    context 'for h36' do
      let(:input_params) do
        {
          assistance_year: Date.today.year,
          month_of_year: Date.today.month
        }
      end

      before do
        @result = subject.call(input_params)
        transmission.reload
      end

      it 'should generate h36 successfully' do
        expect(@result.success?).to be_truthy
      end

      it 'should change pending transmission to transmitted' do
        expect(transmission.status).to eq :transmitted
      end

      it 'should transmission batch file' do
        file_names = Dir.glob("#{outbound_folder}/*").collect do |file|
          File.basename(file)
        end
        expect(file_names.count).to eq 1
        expect(file_names.first).to match(/SBE00ME\.DSH\.EOMIN\.D\d{6}\.T\d{9}\.P\.IN/)
      end

      it 'should update transmission to transmitted state' do
        transmission.transactions.each do |transaction|
          expect(transaction.status).to eq :transmitted
          expect(transaction.transmit_action).to eq :no_transmit
        end
      end
    end

    context 'for errored transactions' do

      let(:transaction_xml) do
        ''
      end

      let(:input_params) do
        {
          assistance_year: Date.today.year,
          month_of_year: Date.today.month
        }
      end

      context 'transaction errored' do
        it 'should record errors' do
          subject.call(input_params)
          transmission.transactions.each do |transaction|
            transaction.reload
            expect(transaction.status).to eq :errored
            expect(transaction.transmit_action).to eq :no_transmit
            expect(transaction.transaction_errors).to eq({ "h36" => "ERROR: Undefined namespace prefix: //irs:IRSHouseholdGrp" })
          end
        end
      end
    end
  end
end
