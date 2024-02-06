# frozen_string_literal: true

require 'rails_helper'
require_relative '../shared_setup'

RSpec.describe Journal::Transactions::Find do
  let(:request_command) { 'request_fdsh_ifsv_determination' }
  let(:request_event_key) { 'VLPService' }
  let(:correlation_id) { '120012300' }
  let(:request_event_attributes) { RequestEventAttributes }

  context 'Operation is called without params' do
    let(:error_message) { 'must provide :correlation_id paramater' }
    it 'should fail validation' do
      expect(described_class.new.call({}).success?).to be_falsey
      expect(described_class.new.call({}).failure).to eq error_message
    end
  end

  context 'Operation is called using a :correlation_id with no matching database record' do
    let(:correlation_id) { 'bogus_id' }
    let(:error_message) do
      "Unable to find transaction with correlation_id: #{correlation_id}"
    end

    it 'should not find a matching record' do
      expect(
        described_class.new.call(correlation_id: correlation_id).success?
      ).to be_falsey
      expect(
        described_class.new.call(correlation_id: correlation_id).failure
      ).to eq error_message
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
      expect(Transaction.all.size).to be > 0
      expect(result.success?).to be_truthy
      expect(result.value!.to_h[:correlation_id]).to eq correlation_id
    end
  end
end
