# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::Jobs::PublishFailureResponse, dbclean: :after_each do
  subject { described_class.new }

  context 'sending invalid params' do
    it 'should return a failure with no params' do
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end

    it 'should return a failure without a job_id' do
      result = subject.call({ correlation_id: "fake_cor_id", event_name: "events.fdsh.ssa_verification_complete" })
      expect(result.failure).to eq 'needs job_id for matching jobs in EA'
    end

    it 'should return a failure with a non-string job_id' do
      result = subject.call({ job_id: 32_746_563, correlation_id: "fake_cor_id", event_name: "events.fdsh.ssa_verification_complete" })
      expect(result.failure).to eq 'needs job_id for matching jobs in EA'
    end

    it 'should return a failure without event name' do
      result = subject.call({ job_id: "fake_job",
                              correlation_id: "fake_cor_id" })
      expect(result.failure).to eq 'needs event name to trigger proper event'
    end

    it 'should return a failure with a non-string event_name' do
      result = subject.call({ event_name: 238_746_273_467, job_id: "fake_job", correlation_id: "fake_cor_id" })
      expect(result.failure).to eq 'needs event name to trigger proper event'
    end

    it 'should return a failure without correlation_id' do
      result = subject.call({ job_id: "fake_job",
                              event_name: "events.fdsh.ssa_verification_complete" })
      expect(result.failure).to eq 'needs correlation_id for matching in EA'
    end

    it 'should return a failure a non-string correlation_id' do
      result = subject.call({ job_id: "fake_job", correlation_id: 2656,
                              event_name: "events.fdsh.ssa_verification_complete" })
      expect(result.failure).to eq 'needs correlation_id for matching in EA'
    end
  end

  context 'sending valid params' do
    before do
      @result = subject.call({ job_id: "fake_job",
                               correlation_id: "fake_cor_id", event_name: "events.fdsh.ssa_verification_complete" })
    end

    it 'should return a success with all required params' do
      expect(@result.success?).to be_truthy
    end
  end
end