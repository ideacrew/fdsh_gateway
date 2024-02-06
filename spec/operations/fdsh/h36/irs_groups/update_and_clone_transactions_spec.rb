# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H36::IrsGroups::UpdateAndCloneTransactions do

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
      result = Fdsh::H36::IrsGroups::UpdateAndCloneTransactions.new.call({})
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(['assistance_year missing', 'month_of_year missing'])
    end

    it "should return failure if assistance_year is missing" do
      result = Fdsh::H36::IrsGroups::UpdateAndCloneTransactions.new.call({ month_of_year: month_of_year })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(['assistance_year missing'])
    end

    it "should return failure if month_of_year is missing" do
      result = Fdsh::H36::IrsGroups::UpdateAndCloneTransactions.new.call({ assistance_year: assistance_year })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq(['month_of_year missing'])
    end

    it "should return failure if no prior transmission exists" do
      result = Fdsh::H36::IrsGroups::UpdateAndCloneTransactions.new.call({ assistance_year: assistance_year,
                                                                           month_of_year: month_of_year })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq('No prior_transmission exists')
    end
  end

  context "valid params" do
    context "assistance_year:current_year and month:first_month" do
      let(:irs_group) do
        create(:h36_irs_group, assistance_year: Date.today.year - 1)
      end

      let(:transmission) do
        create(:month_of_year_transmission, reporting_year: Date.today.year - 1, status: :open,
                                            month_of_year: 12)
      end

      let!(:transaction) do
        create_list(:transmittable_transaction, 5, transmit_action: :transmit, status: :created,
                                                   started_at: Time.now, transactable: irs_group,
                                                   transmission: transmission)
      end

      it "should create a new open transmission and should not update prior transmission to pending state" do
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.count).to eq 1
        result = Fdsh::H36::IrsGroups::UpdateAndCloneTransactions.new.call(assistance_year: Date.today.year,
                                                                           month_of_year: 1)
        expect(result.success?).to be_truthy
        transmission.reload
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.count).to eq 2
        expect(transmission.status).to eq :open
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.status).to eq :open
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.transactions.count).to eq 5
      end
    end

    context "assistance_year:prior_year and month:last_month_of_previous_year" do
      let(:irs_group) do
        create(:h36_irs_group, assistance_year: Date.today.year - 1)
      end

      let(:transmission) do
        create(:month_of_year_transmission, reporting_year: Date.today.year - 1, status: :open,
                                            month_of_year: 12)
      end

      let!(:transaction) do
        create_list(:transmittable_transaction, 5, transmit_action: :transmit, status: :created,
                                                   started_at: Time.now, transactable: irs_group,
                                                   transmission: transmission)
      end

      it "should create a new open transmission and should not update prior transmission to pending state" do
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.count).to eq 1
        result = Fdsh::H36::IrsGroups::UpdateAndCloneTransactions.new.call(assistance_year: Date.today.year - 1,
                                                                           month_of_year: 13)
        expect(result.success?).to be_truthy
        transmission.reload
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.count).to eq 2
        expect(transmission.status).to eq :pending
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.status).to eq :open
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.transactions.count).to eq 5
      end
    end

    context "assistance_year:current_year and month:second_month_of_year" do
      let(:irs_group) do
        create(:h36_irs_group, assistance_year: Date.today.year)
      end

      let(:transmission) do
        create(:month_of_year_transmission, reporting_year: Date.today.year, status: :open,
                                            month_of_year: Date.today.beginning_of_year.month)
      end

      let!(:transaction) do
        create_list(:transmittable_transaction, 5, transmit_action: :transmit, status: :created,
                                                   started_at: Time.now, transactable: irs_group,
                                                   transmission: transmission)
      end

      it "should create a new open transmission and should update prior transmission to pending state" do
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.count).to eq 1
        result = Fdsh::H36::IrsGroups::UpdateAndCloneTransactions.new.call(assistance_year: Date.today.year,
                                                                           month_of_year: 2)
        expect(result.success?).to be_truthy
        transmission.reload
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.count).to eq 2
        expect(transmission.status).to eq :pending
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.status).to eq :open
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.month_of_year).to eq 2
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.transactions.count).to eq 5
      end
    end

    context "assistance_year:prior_year and month:Max transmission month(15) - 1" do
      let(:irs_group) do
        create(:h36_irs_group, assistance_year: Date.today.year - 1)
      end

      let(:transmission) do
        create(:month_of_year_transmission, reporting_year: Date.today.year - 1, status: :open,
                                            month_of_year: 14)
      end

      let!(:transaction) do
        create_list(:transmittable_transaction, 5, transmit_action: :transmit, status: :created,
                                                   started_at: Time.now, transactable: irs_group,
                                                   transmission: transmission)
      end

      it "should create a new open transmission and should update prior transmission to pending state" do
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.count).to eq 1
        result = Fdsh::H36::IrsGroups::UpdateAndCloneTransactions.new.call(assistance_year: Date.today.year - 1,
                                                                           month_of_year: 15)
        expect(result.success?).to be_truthy
        transmission.reload
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.count).to eq 2
        expect(transmission.status).to eq :pending
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.status).to eq :open
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.month_of_year).to eq 15
        expect(H36::Transmissions::Outbound::MonthOfYearTransmission.all.last.transactions.count).to eq 5
      end
    end
  end
end