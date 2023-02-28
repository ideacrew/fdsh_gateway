# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transmittable::Transaction, type: :model do
  before :each do
    DatabaseCleaner.clean
  end

  describe '.transaction_errors=' do
    let(:h41_original_transmission) { FactoryBot.create(:h41_original_transmission) }
    let(:thh_subject) { FactoryBot.create(:h41_aptc_csr_tax_household, :with_transaction, transmission: h41_original_transmission) }
    let(:thh_transaction) { thh_subject.transactions.first }

    context 'with invalid data type' do
      let(:transaction) { thh_transaction }
      let(:new_errors) { 'test' }

      it 'raises ArgumentError' do
        expect {transaction.update_attributes(transaction_errors: new_errors)}.to raise_error(
          ArgumentError, "#{new_errors} must be of type Hash"
        )
      end
    end

    context 'with valid data' do
      let(:transaction) do
        thh_transaction.update_attributes!(transaction_errors: { test: 'dummy error' })
        thh_transaction
      end

      let(:new_errors) { { test10: 'test second error' } }

      it 'stores the new error' do
        transaction.update_attributes(transaction_errors: new_errors)
        expect(transaction.transaction_errors).to eq(
          {
            test: 'dummy error',
            test10: 'test second error'
          }
        )
      end
    end
  end
end
