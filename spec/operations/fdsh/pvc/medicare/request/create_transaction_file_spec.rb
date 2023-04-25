# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

RSpec.describe Fdsh::Pvc::Medicare::Request::CreateTransactionFile do

  before :all do
    DatabaseCleaner.clean
  end

  let(:create_application_requests) do
    (1..17).each do |index|
      Fdsh::Pvc::Medicare::Request::StoreRequest.new.call({ application_hash: "TEST_APPLICATION_#{index}".constantize })
    end
  end

  before do
    create_application_requests
  end

  let(:params) do
    {
      application_payload: JSON.parse(Transaction.first.activities.last.message['request']),
      assistance_year: Transaction.first.activities.last.assistance_year
    }
  end

  subject do
    described_class.new.call(params)
  end

  it "should return transaction xml with applicants count" do
    expect(Transaction.count).to eq 17
    expect(subject.success?).to be_truthy
    expect(Nokogiri::XML(subject.success[0]).errors.empty?).to be_truthy
    expect(subject.success[1]).to eq 1
  end
end
