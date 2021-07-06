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

RSpec.describe Fdsh::Ridp::H139::RequestPrimaryDetermination, "given:
- valid JSON
- invalid family params" do

  let(:json_payload) { "{}" }

  let(:family_contract_mock) do
    instance_double(
      ::AcaEntities::Contracts::Families::FamilyContract
    )
  end

  subject do
    described_class.new.call(json_payload)
  end

  let(:family_contract_validation_result) do
    double(
      success?: false,
      errors: :invalid_family
    )
  end

  before :each do
    allow(::AcaEntities::Contracts::Families::FamilyContract).to receive(:new)
      .and_return(family_contract_mock)
    allow(family_contract_mock).to receive(:call).with({})
                                                 .and_return(family_contract_validation_result)
  end

  it "fails" do
    expect(subject.success?).to be_falsey
    expect(subject.failure).to eq :invalid_family
  end
end