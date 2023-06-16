# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::Jobs::FindOrCreateJob do
  subject { described_class.new }
  let(:key) { :ssa_verification_request}
  let(:title) { 'SSA Verification Request'}
  let(:description) { 'Request for SSA verification to CMS'}
  let(:payload) { { message: "A REQUEST PAYLOAD" } }
  # let(:job_id) { "#{key}_#{DateTime.now.strftime('%Y%m%d%H%M%S%L')}" }

  let(:all_params) do
    {
      key: key,
      title: title,
      description: description,
      payload: payload
    }
  end

  context 'sending valid params' do
    it "Should not have any errors" do
      _result = subject.call(all_params)
      # WIP
    end
  end
end
