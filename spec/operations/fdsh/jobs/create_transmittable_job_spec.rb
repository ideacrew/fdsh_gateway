# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::Jobs::CreateTransmittableJob do
  subject { described_class.new }
  let(:key) { :ssa_verification_request}
  let(:title) { 'SSA Verification Request'}
  let(:description) { 'Request for SSA verification to CMS'}
  let(:payload) { '{ message: "A REQUEST PAYLOAD" }' }

  let(:all_params) do
    {
      key: key,
      title: title,
      description: description,
      payload: payload,
      started_at: DateTime.now,
      publish_on: DateTime.now
    }
  end

  context 'sending valid params' do
    it "Should not have any errors" do
      _result = subject.call(all_params)
      # WIP
    end
  end
end