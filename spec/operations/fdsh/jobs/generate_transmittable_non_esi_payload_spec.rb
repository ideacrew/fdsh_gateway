# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/application_cv3'

RSpec.describe Fdsh::Jobs::GenerateTransmittableNonEsiPayload, dbclean: :after_each do
  include_context "application hash for cv3"

  subject { described_class.new }
  let(:key) { :non_esi_mec_request}
  let(:title) { 'Non Esi Mec Request' }
  let(:description) { 'Request for Non esi mec for CMS' }
  let(:payload) { application_params.to_json }

  let(:all_params) do
    {
      key: key,
      title: title,
      description: description,
      payload: payload,
      started_at: DateTime.now,
      publish_on: DateTime.now,
      correlation_id: 'test'
    }
  end

  context 'sending invalid params' do
    it 'should return a failure with missing key' do
      result = subject.call(all_params.except(:key))
      expect(result.failure).to eq('Transmittable payload cannot be created without a key as a symbol')
    end

    it 'should return a failure when key is not a symbol' do
      all_params[:key] = "Key"
      result = subject.call(all_params)
      expect(result.failure).to eq('Transmittable payload cannot be created without a key as a symbol')
    end

    it 'should return a failure with missing started_at' do
      result = subject.call(all_params.except(:started_at))
      expect(result.failure).to eq('Transmittable payload cannot be created without a started_at as a Datetime')
    end

    it 'should return a failure when started_at is not a Datetime' do
      all_params[:started_at] = Date.today
      result = subject.call(all_params)
      expect(result.failure).to eq('Transmittable payload cannot be created without a started_at as a Datetime')
    end

    it 'should return a failure with missing publish_on' do
      result = subject.call(all_params.except(:publish_on))
      expect(result.failure).to eq('Transmittable payload cannot be created without a publish_on as a Datetime')
    end

    it 'should return a failure when publish_on is not a Datetime' do
      all_params[:publish_on] = Date.today
      result = subject.call(all_params)
      expect(result.failure).to eq('Transmittable payload cannot be created without a publish_on as a Datetime')
    end

    it 'should return a failure when payload not present' do
      result = subject.call(all_params.except(:payload))
      expect(result.failure).to eq('Transmittable payload cannot be created without a payload')
    end

    it 'should return a failure with missing correlation_id' do
      result = subject.call(all_params.except(:correlation_id))
      expect(result.failure).to eq('Transmittable payload cannot be created without a correlation_id a string')
    end

    it 'should return a failure when correlation_id is not a string' do
      all_params[:correlation_id] = Date.today
      result = subject.call(all_params)
      expect(result.failure).to eq('Transmittable payload cannot be created without a correlation_id a string')
    end
  end

  context 'sending valid params' do
    let(:json_payload) do
      { :verifyNonESIMECRequest => { :individualRequestArray => [{ :personSurName => "evidence", :personGivenName => "esi",
                                                                   :personBirthDate => "1988-11-11", :personSexCode => "M",
                                                                   :personSocialSecurityNumber => "518124854", :usStateCode => "DC",
                                                                   :insurancePolicyEffectiveDate => "2021-01-01",
                                                                   :insurancePolicyExpirationDate => "2021-12-31" }] } }
    end
    before do
      @result = subject.call(all_params)
    end

    it "Should not have any errors" do
      expect(@result.success?).to be_truthy
    end

    it "Should return the transaction in hash" do
      expect(@result.value![:transaction]).not_to eq nil
    end

    it "Should have json payload on transaction" do
      expect(@result.value![:transaction].json_payload).not_to eq nil
    end

    it "Should have json payload on transaction" do
      expect(@result.value![:transaction].json_payload).to eq json_payload
    end

    it "Should return the message_id in hash" do
      expect(@result.value![:message_id]).not_to eq nil
    end
  end
end