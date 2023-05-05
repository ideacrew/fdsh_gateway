# frozen_string_literal: true

require 'rails_helper'
require_relative '../shared_setup'

RSpec.describe Journal::Transactions::AddActivity do

  before :all do
    DatabaseCleaner.clean
  end

  let(:request_command) { 'request_fdsh_ifsv_determination' }
  let(:request_event_key) { 'VLPService' }
  let(:request_event_attributes) { RequestEventAttributes }
  let(:correlation_id) { RequestEventAttributes[:request_id] }

  context 'An activitiy is added for a new transaction (new correlation_id)' do
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
        message: request_event_attributes
      }
    end
    it 'should create a new transaction, add the activity and persist to the database' do
      result =
        described_class.new.call(
          correlation_id: correlation_id,
          activity: request_activity
        )

      expect(result.success?).to be_truthy

      # rubocop:disable Layout/FirstArrayElementIndentation
      expect(result.value!.keys).to eq %i[
           activities
           application_id
           correlation_id
           created_at
           family
           family_hbx_id
           magi_medicaid_application
           primary_hbx_id
           updated_at
         ]

      # rubocop:enable Layout/FirstArrayElementIndentation

      expect(result.value![:activities].size).to eq 1
      expect(result.value![:activities].first[:command]).to eq request_command
    end

    context 'and a second activitiy is added for an existing transaction' do
      let(:response_event_key) { 'VLPService' }
      let(:response_command) { 'publish_fdsh_ifsv_determination' }
      let(:response_event_attributes) { ResponseEventAttributes }
      let(:response_status) { '200 OK' }

      let(:response_event) do
        {
          headers: {
            correlation_id: correlation_id,
            status: response_status
          },
          attributes: response_event_attributes
        }
      end

      let(:response_activity) do
        {
          event_key: response_event_key,
          command: response_command,
          correlation_id: response_event[:headers][:correlation_id],
          status: response_event[:headers][:status],
          message: response_event_attributes
        }
      end

      it 'should find the existing transaction, add the new activity, and persist to the database' do
        result =
          described_class.new.call(
            correlation_id: correlation_id,
            activity: response_activity
          )
        expect(result.success?).to be_truthy
        expect(result.value![:activities].size).to eq 2
        expect(result.value![:activities].last[:command]).to eq response_command
      end

      it 'should find the existing transaction, update the magi_medicaid_application and add the new activity' do
        result =
          described_class.new.call(
            correlation_id: correlation_id,
            activity: response_activity,
            magi_medicaid_application: { application_hash: "application_hash" }.to_json,
            application_id: "application_id"
          )

        expect(result.success?).to be_truthy
        expect(result.value![:activities].size).to eq 3
        expect(result.value![:activities].last[:command]).to eq response_command
        expect(result.value![:magi_medicaid_application]).to eq({ application_hash: "application_hash" }.to_json)
        expect(result.value![:application_id]).to eq "application_id"
      end
    end
  end
end
