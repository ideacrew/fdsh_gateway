# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H36::IrsGroups::UpdateH36Transactions do

  before :each do
    DatabaseCleaner.clean
  end

  let(:assistance_year) do
    Date.today.year
  end

  let(:month_of_year) do
    Date.today.month
  end

  context "invalid_params" do
    it "should return failure if params are empty" do
      result = Fdsh::H36::IrsGroups::UpdateH36Transactions.new.call({})
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(['assistance_year missing', 'current_month missing'])
    end

    it "should return failure if assistance_year is missing" do
      result = Fdsh::H36::IrsGroups::UpdateH36Transactions.new.call({ current_month: month_of_year })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(['assistance_year missing'])
    end

    it "should return failure if current_month is missing" do
      result = Fdsh::H36::IrsGroups::UpdateH36Transactions.new.call({ assistance_year: assistance_year })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(['current_month missing'])
    end

    it "should return failure if no open transmission exists" do
      result = Fdsh::H36::IrsGroups::UpdateH36Transactions.new.call({ assistance_year: assistance_year,
                                                                      current_month: month_of_year })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq('Unable to update transactions')
    end
  end

  context "valid params" do
    let(:irs_group) do
      create(:h36_irs_group, assistance_year: Date.today.year - 1)
    end

    let(:transmission) do
      create(:month_of_year_transmission, reporting_year: Date.today.year, status: :open,
                                          month_of_year: Date.today.month - 1)
    end

    let!(:transaction) do
      create_list(:transmittable_transaction, 5, transmit_action: :transmit, status: :created,
                                                 started_at: Time.now, transactable: irs_group,
                                                 transmission: transmission)
    end

    # NOTE: running this spec in January will cause it to fail
    xit "should create a new open transmission and should not update prior transmission to pending state" do
      expect(::H36::Transmissions::Outbound::MonthOfYearTransmission.all.count).to eq 1
      result = Fdsh::H36::IrsGroups::UpdateH36Transactions.new.call(assistance_year: Date.today.year,
                                                                    current_month: Date.today.month)
      expect(result.success?).to be_truthy
      transmission.reload
      expect(::H36::Transmissions::Outbound::MonthOfYearTransmission.all.count).to eq 2
      expect(transmission.status).to eq :pending
      expect(::H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.status).to eq :open
      expect(::H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.transactions.count).to eq 5
    end
  end
end