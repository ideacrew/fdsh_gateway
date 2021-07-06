# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::Ridp::H139::RequestPrimaryDetermination, "given invalid JSON" do

  let(:json_payload) { "\kdslkjfe;" }

  subject do
    described_class.new.call(json_payload)
  end

  it "fails" do
    expect(subject.success?).to be_falsey
    expect(subject.failure).to eq :invalid_json
  end
end