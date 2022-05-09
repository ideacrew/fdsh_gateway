# frozen_string_literal: true

require 'rails_helper'
require_relative '../shared_setup'

RSpec.describe Journal::Transactions::FindOrCreate do

  before :all do
    DatabaseCleaner.clean
  end

  let(:request_command) { 'request_fdsh_ifsv_determination' }
  let(:request_event_key) { 'VLPService' }
  let(:correlation_id) { '120012300' }
  let(:request_event_attributes) { RequestEventAttributes }

  context 'Operation is called without params' do
    let(:errors) { { :correlation_id => ["is missing", "must be a string"] } }
    it 'should fail validation' do
      expect(described_class.new.call({}).success?).to be_falsey
      expect(described_class.new.call({}).failure.errors.to_h).to eq errors
    end
  end

  context 'Operation is called using a :correlation_id with no matching database record' do
    let(:correlation_id) { 'brand_new_id' }
    let(:result) { described_class.new.call(correlation_id: correlation_id) }

    before do
      expect(Transaction.count).to eq 0
    end

    it 'should create a new Transaction record' do
      expect(result.success?).to eq true
      expect(Transaction.first.correlation_id).to eq 'brand_new_id'
    end
  end

  context 'An activitiy record is added to the database' do
    let(:request_event) do
      {
        headers: {
          correlation_id: correlation_id
        },
        attributes: request_event_attributes
      }
    end

    let(:request_activity) do
      {
        event_key: request_event_key,
        command: request_command,
        correlation_id: request_event[:headers][:correlation_id],
        message: request_event_attributes.merge(request_id: correlation_id)
      }
    end

    it 'should find and return a Transaction hash for the supplied :correlation_id' do
      transaction =
        Journal::Transactions::AddActivity.new.call(
          correlation_id: correlation_id,
          activity: request_activity
        )

      result =
        described_class.new.call(
          correlation_id: transaction.value![:correlation_id]
        )
      expect(::Transaction.count).to be > 0
      expect(result.success?).to be_truthy
      expect(result.value!.to_h[:correlation_id]).to eq correlation_id
    end
  end
end
