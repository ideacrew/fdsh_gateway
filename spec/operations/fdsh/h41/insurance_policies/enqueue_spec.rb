# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response2'

RSpec.describe Fdsh::H41::InsurancePolicies::Enqueue do
  subject { described_class.new.call(input_params) }

  before :all do
    DatabaseCleaner.clean
  end

  after :each do
    DatabaseCleaner.clean
  end

  describe '#call' do
    include_context 'family response with one policy'

    context 'with valid input params' do
      let!(:corrected_transmission) { FactoryBot.create(:h41_corrected_transmission) }
      let!(:original_transmission)  { FactoryBot.create(:h41_original_transmission) }
      let!(:void_transmission)      { FactoryBot.create(:h41_void_transmission) }

      let(:corrected_transactions_transmissions_transactions) do
        Transmittable::TransactionsTransmissions.where(transmission: corrected_transmission).map(&:transaction)
      end

      let(:original_transactions_transmissions_transactions) do
        Transmittable::TransactionsTransmissions.where(transmission: original_transmission).map(&:transaction)
      end

      let(:void_transactions_transmissions_transactions) do
        Transmittable::TransactionsTransmissions.where(transmission: void_transmission).map(&:transaction)
      end

      let(:transmitted_transactions) do
        original = Transmittable::TransactionsTransmissions.where(transmission: original_transmission).first
        Transmittable::Transaction.each do |taction|
          taction.update_attributes!(status: :transmitted, transmit_action: :no_transmit)
          FactoryBot.create(:transmission_path, transmission: original, transaction: taction)
        end
      end

      let(:transactions_for_first_subject) do
        ::H41::InsurancePolicies::AptcCsrTaxHousehold.all.first.transactions
      end

      let(:transactions_for_second_subject) do
        ::H41::InsurancePolicies::AptcCsrTaxHousehold.all.second.transactions
      end

      let(:posted_family) { ::H41::InsurancePolicies::PostedFamily.all.first }
      let(:insurance_policy) { posted_family.insurance_policies.first }
      let(:aptc_csr_tax_household) { insurance_policy.aptc_csr_tax_households.first }

      let(:input_params) do
        {
          affected_policies: [policy_id],
          assistance_year: Date.today.year,
          correlation_id: 'cor100',
          family: family_hash
        }
      end

      let(:original_first_transaction) do
        original_transactions_transmissions_transactions.first
      end

      # This results in creation of an errored transaction with transaction_errors
      context 'with invalid city' do
        let(:city) { '04001' }

        it 'adds transaction_errors to the transaction object' do
          subject
          expect(original_first_transaction.transaction_errors).not_to be_empty
          expect(original_first_transaction.transaction_errors.keys).to include('transaction_xml')
        end

        it 'creates transaction in errored status and no_transmit transmit_action' do
          subject
          expect(original_first_transaction.status).to eq(:errored)
          expect(original_first_transaction.transmit_action).to eq(:no_transmit)
        end
      end

      context 'with submitted policy' do
        context 'with transmit_pending transactions' do
          before { described_class.new.call(input_params) }

          let(:original_second_transaction) do
            original_transactions_transmissions_transactions.second
          end

          let(:all_subject_transactions) do
            ::H41::InsurancePolicies::AptcCsrTaxHousehold.all.flat_map(&:transactions)
          end

          it 'updates transmit_pending transactions to no_transmit' do
            expect(original_first_transaction.status).to eq(:created)
            expect(original_first_transaction.transmit_action).to eq(:transmit)
            expect(original_first_transaction.transactable.transaction_xml).not_to be_empty
            subject
            expect(original_first_transaction.reload.status).to eq(:superseded)
            expect(original_first_transaction.reload.transmit_action).to eq(:no_transmit)
            expect(original_first_transaction.transactable.transaction_xml).not_to be_empty
          end

          it 'creates transactions for original transmission' do
            subject
            expect(corrected_transactions_transmissions_transactions.map(&:id)).to eq([])
            expect(original_transactions_transmissions_transactions.map(&:id)).to eq(all_subject_transactions.map(&:id))
            expect(void_transactions_transmissions_transactions.map(&:id)).to eq([])
          end

          it 'creates subjects with transmission_type' do
            expect(
              original_transactions_transmissions_transactions.map(&:transactable).flat_map(&:original).uniq
            ).to eq([true])
          end

          it 'creates new transaction with status and transmit_action' do
            subject
            expect(original_second_transaction.transmit_action).to eq(:transmit)
            expect(original_second_transaction.status).to eq(:created)
            expect(original_second_transaction.transactable.transaction_xml).not_to be_empty
          end
        end

        context 'with transmitted transactions' do
          before do
            described_class.new.call(input_params)
            transmitted_transactions
            subject
          end

          it 'will not update transmitted transactions' do
            expect(original_first_transaction.reload.status).to eq(:transmitted)
            expect(original_first_transaction.reload.transmit_action).to eq(:no_transmit)
          end

          it 'creates transactions for corrected transmission' do
            expect(corrected_transactions_transmissions_transactions.map(&:id)).to eq(transactions_for_second_subject.map(&:id))
            expect(original_transactions_transmissions_transactions.map(&:id)).to eq(transactions_for_first_subject.map(&:id))
            expect(void_transactions_transmissions_transactions.map(&:id)).to eq([])
          end

          it 'creates subjects with transmission_type' do
            expect(
              corrected_transactions_transmissions_transactions.map(&:transactable).flat_map(&:corrected).uniq
            ).to eq([true])
            expect(
              original_transactions_transmissions_transactions.map(&:transactable).flat_map(&:original).uniq
            ).to eq([true])
          end
        end
      end

      context 'with canceled policy' do
        before { described_class.new.call(input_params1) }

        let(:input_params1) do
          input_params[:family][:households].first[:insurance_agreements].first[:insurance_policies].first[:aasm_state] = 'submitted'
          input_params
        end

        let(:update_policy_aasm_state) do
          input_params[:family][:households].first[:insurance_agreements].first[:insurance_policies].first[:aasm_state] = 'canceled'
          input_params
        end

        let(:void_first_transaction) do
          void_transactions_transmissions_transactions.first
        end

        context 'with transmit_pending transactions' do
          before do
            update_policy_aasm_state
            subject
          end

          it 'will not update transmitted transactions' do
            expect(original_first_transaction.status).to eq(:superseded)
            expect(original_first_transaction.transmit_action).to eq(:no_transmit)
            expect(void_first_transaction.status).to eq(:blocked)
            expect(void_first_transaction.transmit_action).to eq(:no_transmit)
            expect(void_first_transaction.transactable.transaction_xml).to eq('')
            expect(void_first_transaction.transactable.transaction_xml).not_to be_nil
          end

          it 'creates transactions for void transmission' do
            expect(corrected_transactions_transmissions_transactions.map(&:id)).to eq([])
            expect(original_transactions_transmissions_transactions.map(&:id)).to eq(transactions_for_first_subject.map(&:id))
            expect(void_transactions_transmissions_transactions.map(&:id)).to eq(transactions_for_second_subject.map(&:id))
          end

          it 'creates subjects with transmission_type' do
            expect(
              original_transactions_transmissions_transactions.map(&:transactable).flat_map(&:original).uniq
            ).to eq([true])
            expect(
              void_transactions_transmissions_transactions.map(&:transactable).flat_map(&:void).uniq
            ).to eq([true])
          end
        end

        context 'with transmitted transactions' do
          before do
            transmitted_transactions
            update_policy_aasm_state
            subject
          end

          it 'will not update transmitted transactions' do
            expect(original_first_transaction.status).to eq(:transmitted)
            expect(original_first_transaction.transmit_action).to eq(:no_transmit)
            expect(void_first_transaction.status).to eq(:created)
            expect(void_first_transaction.transmit_action).to eq(:transmit)
            expect(void_first_transaction.transactable.transaction_xml).not_to be_empty
          end

          it 'creates transactions for void transmission' do
            expect(corrected_transactions_transmissions_transactions.map(&:id)).to eq([])
            expect(original_transactions_transmissions_transactions.map(&:id)).to eq(transactions_for_first_subject.map(&:id))
            expect(void_transactions_transmissions_transactions.map(&:id)).to eq(transactions_for_second_subject.map(&:id))
          end

          it 'creates subjects with transmission_type' do
            expect(
              original_transactions_transmissions_transactions.map(&:transactable).flat_map(&:original).uniq
            ).to eq([true])
            expect(
              void_transactions_transmissions_transactions.map(&:transactable).flat_map(&:void).uniq
            ).to eq([true])
          end
        end
      end
    end

    context 'with invalid input params' do
      context 'missing params' do
        let(:input_params) { {} }

        it 'returns failure with error message' do
          expect(
            subject.failure
          ).to eq('Invalid affected_policies: . Please pass in a list of affected_policies.')
        end
      end

      context 'bad input family Cv' do
        let(:input_params) do
          {
            affected_policies: [policy_id],
            assistance_year: Date.today.year,
            correlation_id: 'correlation_id',
            family: family_hash.merge(hbx_id: nil)
          }
        end

        it 'returns failure with errors' do
          expect(
            subject.failure
          ).to eq({ hbx_id: ['must be filled'] })
        end
      end

      context 'without previous transactions' do
        let(:input_params) do
          {
            affected_policies: [policy_id],
            assistance_year: Date.today.year,
            correlation_id: 'cor100',
            family: family_hash
          }
        end

        before { subject }

        it 'returns a failure with a message' do
          expect(
            subject.failure
          ).to match(/Unable to find OpenTransmission for type: /)
        end
      end
    end
  end
end
