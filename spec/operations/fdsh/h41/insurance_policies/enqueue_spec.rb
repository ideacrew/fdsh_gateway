# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response2'
# require 'shared_examples/h41_open_transmissions'

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

    let(:corrected_transmission) { ::H41::Transmissions::Outbound::CorrectedTransmission.open.first }
    let(:original_transmission) { ::H41::Transmissions::Outbound::OriginalTransmission.open.first }
    let(:void_transmission) { ::H41::Transmissions::Outbound::VoidTransmission.open.first }

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
      Transmittable::Transaction.update_all(status: :transmitted, transmit_action: :no_transmit)
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

    # include_context 'open transmissions for h41'

    # without previous transactions(DONE)
    # with previous transactions that are transmitted(DONE)
    # with previous transactions that are transmit_pending(DONE)
    # with canceled policy
    context 'with valid input params' do
      let(:input_params) { { correlation_id: 'cor100', family: family_hash } }

      let(:original_first_transaction) do
        original_transactions_transmissions_transactions.first
      end

      context 'without previous transactions' do
        before { subject }

        it 'returns a success with a message' do
          expect(
            subject.success
          ).to eq('Successfully enqueued family with hbx_id: 43456, contract_holder_id: 1000595')
        end

        it 'creates transactions for original transmission' do
          expect(corrected_transactions_transmissions_transactions.map(&:id)).to eq([])
          expect(original_transactions_transmissions_transactions.map(&:id)).to eq(aptc_csr_tax_household.transactions.map(&:id))
          expect(void_transactions_transmissions_transactions.map(&:id)).to eq([])
        end

        it 'creates transaction with status and transmit_action' do
          expect(original_first_transaction.status).to eq(:created)
          expect(original_first_transaction.transmit_action).to eq(:transmit)
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
            subject
            expect(original_first_transaction.reload.status).to eq(:superseded)
            expect(original_first_transaction.reload.transmit_action).to eq(:no_transmit)
          end

          it 'creates transactions for original transmission' do
            subject
            expect(corrected_transactions_transmissions_transactions.map(&:id)).to eq([])
            expect(original_transactions_transmissions_transactions.map(&:id)).to eq(all_subject_transactions.map(&:id))
            expect(void_transactions_transmissions_transactions.map(&:id)).to eq([])
          end

          it 'creates new transaction with status and transmit_action' do
            subject
            expect(original_second_transaction.transmit_action).to eq(:transmit)
            expect(original_second_transaction.status).to eq(:created)
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
            expect(void_first_transaction.status).to eq(:superseded)
            expect(void_first_transaction.transmit_action).to eq(:no_transmit)
          end

          it 'creates transactions for void transmission' do
            expect(corrected_transactions_transmissions_transactions.map(&:id)).to eq([])
            expect(original_transactions_transmissions_transactions.map(&:id)).to eq(transactions_for_first_subject.map(&:id))
            expect(void_transactions_transmissions_transactions.map(&:id)).to eq(transactions_for_second_subject.map(&:id))
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
          end

          it 'creates transactions for void transmission' do
            expect(corrected_transactions_transmissions_transactions.map(&:id)).to eq([])
            expect(original_transactions_transmissions_transactions.map(&:id)).to eq(transactions_for_first_subject.map(&:id))
            expect(void_transactions_transmissions_transactions.map(&:id)).to eq(transactions_for_second_subject.map(&:id))
          end
        end
      end
    end

    context 'with invalid input params' do
      context 'bad input family Cv' do
        let(:input_params) do
          {
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
    end
  end
end
