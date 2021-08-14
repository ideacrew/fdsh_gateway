# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_setup'

RSpec.describe Journal::TransactionContract do
  # include_context('with events')

  context 'Calling contract with Valid params' do
    let(:request_event_message) { RequestEventMessage }
    let(:response_event_message) { ResponseEventMessage }

    let(:correlation_id) { request_event_message[:request_id] }

    let(:request_command) { 'request_fdsh_ifsv_determination' }
    let(:request_event_key) { 'IFSVService' }
    let(:request_status) { nil }

    # let(:message) {  AcaEntities::Fdsh::Ifsv::H9t::Data::Fti::Response }
    let(:response_command) { 'publish_fdsh_ifsv_determination' }
    let(:response_event_key) { 'IFSVService' }
    let(:response_status) { '200 OK' }

    let(:request_activity) do
      {
        correlation_id: correlation_id,
        command: request_command,
        event_key: request_event_key,
        message: request_event_message
      }
    end

    let(:response_activity) do
      {
        correlation_id: correlation_id,
        command: response_command,
        event_key: response_event_key,
        message: response_event_message,
        status: response_status
      }
    end

    let(:activities) { [request_activity, response_activity] }

    let(:required_params) { { correlation_id: correlation_id } }
    let(:optional_params) { { activities: activities } }
    let(:all_params) { required_params.merge(optional_params) }

    context 'Calling the contract with required params' do
      it 'should pass vaidation' do
        result = described_class.new.call(required_params)
        expect(result.success?).to be_truthy
        expect(result.to_h).to eq required_params
      end
    end

    context 'Calling the contract with all params' do
      it 'should pass vaidation' do
        result = described_class.new.call(all_params)
        expect(result.success?).to be_truthy
        expect(result.to_h).to eq all_params
      end
    end
  end

  context 'Calling the contract with no params' do
    let(:error_message) do
      { correlation_id: ['is missing', 'must be a string'] }
    end
    it 'should fail vaidation' do
      result = described_class.new.call({})
      expect(result.failure?).to be_truthy
      expect(result.errors.to_h).to eq error_message
    end
  end
end
