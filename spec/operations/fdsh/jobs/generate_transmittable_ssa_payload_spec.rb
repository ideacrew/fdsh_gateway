# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/person_cv3'

RSpec.describe Fdsh::Jobs::GenerateTransmittableSsaPayload do
  include_context "person hash for cv3"

  subject { described_class.new }
  let(:key) { :ssa_verification_request}
  let(:title) { 'SSA Verification Request'}
  let(:description) { 'Request for SSA verification to CMS'}
  let(:payload) { person_params.to_json }

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

  context 'sending valid params' do
    it "Should not have any errors" do
      _result = subject.call(all_params)
      # WIP
    end
  end
end