# frozen_string_literal: true

require 'spec_helper'
require 'medicare_metadata_setup'

RSpec.describe Fdsh::Pvc::Medicare::Request::StoreRequest do

  before :all do
    DatabaseCleaner.clean
  end

  let(:params) do
    { application_hash: TEST_APPLICATION_1 }
  end

  subject do
    described_class.new.call(params)
  end

  it "should create transaction with activity" do
    expect(Transaction.count).to eq 0
    expect(subject.success?).to be_truthy
    expect(Transaction.count).to eq 1
    expect(Transaction.first.activities).to be_present
  end
end
