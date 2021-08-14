# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_setup'

RSpec.describe ::Journal::ActivityContract do
  context 'Calling contract with Valid params' do
    let(:correlation_id) { '00998877' }

    let(:request_command) { 'request_fdsh_ifsv_determination' }
    let(:request_event_key) { 'IFSVService' }
    let(:request_message) { RequestEventMessage }

    let(:request) do
      {
        correlation_id: correlation_id,
        command: request_command,
        event_key: request_event_key,
        message: request_message
      }
    end

    let(:required_params) do
      { correlation_id: correlation_id, event_key: request_event_key }
    end

    let(:optional_params) do
      { command: request_command, message: request_message, status: nil }
    end

    let(:all_params) { required_params.merge(optional_params) }

    context 'Calling the contract with required params' do
      it 'should pass validation' do
        result = described_class.new.call(required_params)
        expect(result.success?).to be_truthy
        expect(result.to_h).to eq required_params
      end
    end

    context 'Calling the contract with all params' do
      it 'should pass validation' do
        result = described_class.new.call(all_params)
        expect(result.success?).to be_truthy
        expect(result.to_h).to eq all_params
      end
    end
  end

  context 'Calling the contract with no params' do
    let(:error_message) do
      {
        correlation_id: ['is missing', 'must be a string'],
        event_key: ['is missing', 'must be a string']
      }
    end
    it 'should fail validation' do
      result = described_class.new.call({})
      expect(result.failure?).to be_truthy
      expect(result.errors.to_h).to eq error_message
    end
  end
end
