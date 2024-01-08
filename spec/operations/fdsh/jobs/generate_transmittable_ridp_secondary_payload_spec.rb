# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/family_cv3_secondary_ridp'

RSpec.describe Fdsh::Jobs::GenerateTransmittableRidpSecondaryPayload, dbclean: :after_each do
  include_context "family cv3 with secondary ridp attestation"

  subject { described_class.new }
  let(:key) { :ridp_secondary_verification_request}
  let(:title) { 'RIDP Secondary Request' }
  let(:description) { 'RIDP Secondary verification request to CMS' }
  let(:payload) { family_hash.to_json }

  let(:all_params) do
    {
      key: key,
      title: title,
      description: description,
      payload: payload,
      started_at: DateTime.now,
      publish_on: DateTime.now,
      correlation_id: '12348',
      session_id: 'test',
      transmission_id: 'test'
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
      expect(result.failure).to eq('Transmittable payload cannot be created without a transmission_id and correlation_id')
    end

    it 'should return a failure when correlation_id is not a string' do
      all_params[:correlation_id] = Date.today
      result = subject.call(all_params)
      expect(result.failure).to eq('Transmittable payload cannot be created without a transmission_id and correlation_id')
    end

    it 'should return a failure with missing transmission_id' do
      result = subject.call(all_params.except(:transmission_id))
      expect(result.failure).to eq('Transmittable payload cannot be created without a transmission_id and correlation_id')
    end

    it 'should return a failure when transmission_id is not a string' do
      all_params[:transmission_id] = Date.today
      result = subject.call(all_params)
      expect(result.failure).to eq('Transmittable payload cannot be created without a transmission_id and correlation_id')
    end
  end

  context 'sending valid params' do
    let(:json_payload) do
      { "ridpRequest" =>
        { "secondaryRequest" =>
          { "hubReferenceNumber" => "test",
            "sessionIdentification" => "347567asghfjgshfg",
            "verificationAnswerArray" => [
              { "verificationAnswerSet" => { "verificationAnswer" => "1", "verificationQuestionNumber" => "1" } },
              { "verificationAnswerSet" => { "verificationAnswer" => "1", "verificationQuestionNumber" => "2" } },
              { "verificationAnswerSet" => { "verificationAnswer" => "2", "verificationQuestionNumber" => "3" } }
            ] } } }
    end

    context 'without existing subject' do
      before do
        @result = subject.call(all_params)
      end

      it "Should have an errors" do
        expect(@result.success?).to be_falsey
      end

      it "Should return a failure" do
        expect(@result.failure).to eq "Unable to find existing person subject"
      end
    end

    context 'with existing subject' do
      before do
        FactoryBot.create(:transmittable_person)
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
end