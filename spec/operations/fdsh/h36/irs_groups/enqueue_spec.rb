# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response3'

RSpec.describe Fdsh::H36::IrsGroups::Enqueue do
  include_context "family response"

  before :each do
    DatabaseCleaner.clean
  end

  let(:assistance_year) do
    Date.today.year
  end

  context "invalid params" do
    it "should return failure if params do not have family" do
      result = described_class.new.call({})
      expect(result.failure?).to eq true
      expect(result.failure).to eq "Please pass in family"
    end

    it "should return failure if no valid family hash is passed" do
      result = described_class.new.call({ family: {} })
      expect(result.failure?).to eq true
    end

    it "should return failure if assistance year is blank" do
      result = described_class.new.call({ family: family_hash })
      expect(result.failure?).to eq true
    end

    it "should return failure if correlation_id is blank" do
      result = described_class.new.call({ family: family_hash, assistance_year: Date.today.year })
      expect(result.failure?).to eq true
    end
  end

  context "valid params" do
    let!(:month_of_year_transmission) do
      create(:month_of_year_transmission, reporting_year: Date.today.year, month_of_year: Date.today.month)
    end

    context "create a new irs_group" do
      it "should create a new irs_group if no irs_group exists and puts the transaction in created state" do
        result = described_class.new.call({ correlation_id: SecureRandom.uuid,
                                            family: family_hash,
                                            assistance_year: assistance_year,
                                            month_of_year: Date.today.month })
        expect(result.success?).to be_truthy
        expect(::H36::IrsGroups::IrsGroup.all.count).to eq 1
        expect(::H36::IrsGroups::IrsGroup.all.last.transactions.first.status).to eq(:created)
      end
    end

    context "existing irs_group with transactions in pending state" do
      it "should move existing irs_group transactions to no_trasmit state and create a new irs_group" do
        irs_group = create(:h36_irs_group, family_hbx_id: family_hash[:hbx_id], assistance_year: Date.today.year)
        _pending_transaction = create(:transmittable_transaction,
                                      status: :created, started_at: Time.now,
                                      transactable: irs_group,
                                      transmission: month_of_year_transmission)
        expect(irs_group.transactions.first.status).to eq(:created)
        result = described_class.new.call({ correlation_id: SecureRandom.uuid, family: family_hash,
                                            assistance_year: assistance_year,
                                            month_of_year: Date.today.month })
        expect(result.success?).to be_truthy
        expect(irs_group.reload.transactions.first.status).to eq(:superseded)
        expect(month_of_year_transmission.reload.transactions.count).to eq 2
        expect(::H36::IrsGroups::IrsGroup.all.count).to eq 2
        expect(::H36::IrsGroups::IrsGroup.all.last.transactions.first.status).to eq(:created)
      end
    end

    context "no active policies" do
      let(:policy_aasm_state) { "canceled" }

      it "should create irs_group with transactions in no_transmit state" do
        result = described_class.new.call({ correlation_id: SecureRandom.uuid,
                                            family: family_hash, assistance_year: assistance_year,
                                            month_of_year: Date.today.month })
        expect(result.success?).to be_truthy
        expect(::H36::IrsGroups::IrsGroup.all.count).to eq 1
        expect(::H36::Transmissions::Outbound::MonthOfYearTransmission.all.count).to eq 1
        expect(::H36::Transmissions::Outbound::MonthOfYearTransmission.all.first.reporting_year).to eq assistance_year
        expect(::H36::IrsGroups::IrsGroup.all.last.transactions.first.status).to eq(:excluded)
        expect(::H36::IrsGroups::IrsGroup.all.last.transactions.first.transmit_action).to eq(:no_transmit)
      end
    end
  end
end
