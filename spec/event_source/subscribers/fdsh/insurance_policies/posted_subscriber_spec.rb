# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_response3'

RSpec.describe Subscribers::Fdsh::InsurancePolicies::PostedSubscriber, dbclean: :after_each do
  include_context "family response"

  let(:logger) { instance_double("::Logger", info: nil, debug: nil, warn: nil, error: nil) }

  # Please refactor this test once we move to logic for multiple assistance years into an operation
  describe 'process_insurance_policies_posted_event_for_h36' do
    context "prospective assistance_year" do
      let!(:month_of_year_transmission) do
        create(:month_of_year_transmission, reporting_year: Date.today.year + 1, month_of_year: 1)
      end
      it "should return success" do
        expect(month_of_year_transmission.transactions.all.count).to eq 0
        described_class.new.send(:process_insurance_policies_posted_event_for_h36, logger,
                                 { family: family_hash },
                                 headers: { 'assistance_year' => Date.today.year + 1 },
                                 correlation_id: '1234')
        expect(::H36::IrsGroups::IrsGroup.all.count).to eq 1
        expect(::H36::IrsGroups::IrsGroup.all.last.assistance_year).to eq Date.today.year + 1
        month_of_year_transmission.reload
        expect(month_of_year_transmission.transactions.all.count).to eq 1
      end
    end

    context "current assistance_year" do
      let!(:month_of_year_transmission) do
        create(:month_of_year_transmission, reporting_year: Date.today.year, month_of_year: Date.today.month)
      end
      it "should return success" do
        expect(month_of_year_transmission.transactions.all.count).to eq 0
        described_class.new.send(:process_insurance_policies_posted_event_for_h36, logger,
                                 { family: family_hash },
                                 headers: { 'assistance_year' => Date.today.year },
                                 correlation_id: '1234')
        expect(::H36::IrsGroups::IrsGroup.all.last.assistance_year).to eq Date.today.year
        month_of_year_transmission.reload
        expect(month_of_year_transmission.transactions.all.count).to eq 1
      end
    end

    context "previous assistance_year" do
      let!(:month_of_year_transmission) do
        create(:month_of_year_transmission, reporting_year: Date.today.year - 1, month_of_year: 13)
      end

      before do
        allow(Date).to receive(:today).and_return Date.new(Date.today.year, 1, 1)
      end

      it "should return success" do
        expect(month_of_year_transmission.transactions.all.count).to eq 0
        described_class.new.send(:process_insurance_policies_posted_event_for_h36, logger,
                                 { family: family_hash },
                                 headers: { 'assistance_year' => Date.today.year - 1 },
                                 correlation_id: '1234')
        expect(::H36::IrsGroups::IrsGroup.all.last.assistance_year).to eq Date.today.year - 1
        month_of_year_transmission.reload
        expect(month_of_year_transmission.transactions.all.count).to eq 1
      end
    end
  end
end
