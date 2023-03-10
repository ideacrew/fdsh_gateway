# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H36::Request::BuildAndPersistH36Xml do

  before :each do
    DatabaseCleaner.clean
  end

  let(:assistance_year) do
    Date.today.year
  end

  context "invalid params or data" do
    it "should return failure if assistance_year is blank" do
      result = Fdsh::H36::Request::BuildAndPersistH36Xml.new.call({})
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq('Please provide transmission')
    end
  end

  context "valid params" do
    let!(:transmission) do
      create(:month_of_year_transmission, reporting_year: assistance_year)
    end

    it 'should throw an error if no valid transactions exists' do
      irs_group = create(:h36_irs_group, assistance_year: Date.today.year)
      create(:transmittable_transaction, transmit_action: :no_transmit, started_at: Time.now, transactable: irs_group,
                                         transmission: transmission)
      result = Fdsh::H36::Request::BuildAndPersistH36Xml.new.call({ transmission: transmission })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq('No transactions to transmit')
    end

    it 'should return success if publish an event for valid transactions for open transmission' do
      irs_group = create(:h36_irs_group, assistance_year: assistance_year)
      _transaction = create(:transmittable_transaction, transmit_action: :transmit,
                                                        started_at: Time.now, transactable: irs_group,
                                                        transmission: transmission)
      result = Fdsh::H36::Request::BuildAndPersistH36Xml.new.call({ transmission: transmission })
      expect(result.success?).to be_truthy
      expect(Transmittable::TransactionsTransmissions.all.count).to eq 1
      expect(Transmittable::Transaction.all.count).to eq 1
    end
  end
end