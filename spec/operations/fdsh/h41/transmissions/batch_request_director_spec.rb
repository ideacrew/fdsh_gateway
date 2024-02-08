# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::Transmissions::BatchRequestDirector do
  subject { described_class.new }

  before :each do
    FileUtils.rm_rf(Rails.root.join("h41_transmissions").to_s)
  end

  after :all do
    FileUtils.rm_rf(Rails.root.join("h41_transmissions").to_s)
  end

  after :each do
    DatabaseCleaner.clean
  end

  let(:report_kind) { :h41_1095a }

  context 'with invalid input params' do
    context 'bad report_type' do
      let(:input_params) do
        {}
      end

      it 'returns failure with errors' do
        result = subject.call(input_params)
        expect(result.failure).to eq('transactions collection required')
      end
    end

    context 'bad report_type' do
      let(:input_params) do
        {
          transactions: [double]
        }
      end

      it 'returns failure with errors' do
        result = subject.call(input_params)
        expect(result.failure).to eq('outbound folder name missing')
      end
    end
  end

  def init_content_file_builder(values, new_batch_reference, old_batch_reference = nil)
    options = {
      transmission_kind: values[:report_type],
      old_batch_reference: old_batch_reference,
      new_batch_reference: new_batch_reference
    }

    Fdsh::H41::Transmissions::ContentFileBuilder.new(options) do |transaction, transmission_details|
      transaction.status = :transmitted
      transaction.transmit_action = :no_transmit
      transaction.save

      transmission_path = transaction.transmission.transmission_paths.build(
        transmission_details.merge(transaction_id: transaction.id)
      )
      transmission_path.save
    end
  end

  describe 'call' do
    let!(:insurance_polices) do
      create_list(:h41_insurance_policy, 20, :with_aptc_csr_tax_households, transaction_xml: transaction_xml,
                                                                            transmission: open_transmission)
    end

    let(:outbound_folder) do
      Rails.root.join("h41_transmissions").to_s
    end

    let!(:open_transmission) { FactoryBot.create(:h41_original_transmission) }
    let(:transaction_xml) do
      File.read(Rails.root.join("spec/test_payloads/h41/original.xml").to_s)
    end

    let(:input_params) do
      {
        transactions: Transmittable::Transaction.where(:id.in => open_transmission.transactions.pluck(:id)),
        transmission_kind: :original,
        old_batch_reference: nil,
        outbound_folder_name: 'h41_transmissions',
        transmission_builder: init_content_file_builder({ report_type: :original },
                                                        Time.now.gmtime.strftime("%Y-%m-%dT%H:%M:%SZ"),
                                                        nil)
      }
    end

    before do
      @result = subject.call(input_params)
      open_transmission.reload
    end

    it 'should update all transactions under a transmission to transmitted state' do
      open_transmission.transactions.each do |transaction|
        expect(transaction.status).to eq :transmitted
        expect(transaction.transmit_action).to eq :no_transmit
      end
    end
  end
end
