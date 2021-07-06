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

RSpec.describe Fdsh::Ridp::H139::RequestPrimaryDetermination, "given:
- valid JSON
- valid family params
- invalid determination request params" do

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
      success?: true,
      values: {}
    )
  end

  let(:family_mock) do
    instance_double(
      AcaEntities::Families::Family
    )
  end

  let(:transform_operation_mock) do
    instance_double(
      Fdsh::Ridp::H139::TransformFamilyToPrimaryDetermination
    )
  end

  before :each do
    allow(::AcaEntities::Contracts::Families::FamilyContract).to receive(:new)
      .and_return(family_contract_mock)
    allow(family_contract_mock).to receive(:call).with({})
                                                 .and_return(family_contract_validation_result)
    allow(AcaEntities::Families::Family).to receive(:new).with({})
                                                         .and_return(family_mock)
    allow(Fdsh::Ridp::H139::TransformFamilyToPrimaryDetermination).to receive(:new)
      .and_return(transform_operation_mock)
    allow(transform_operation_mock).to receive(:call).with(family_mock)
                                                     .and_return(Dry::Monads::Result::Failure.call(nil))
  end

  it "fails" do
    expect(subject.success?).to be_falsey
  end
end

RSpec.describe Fdsh::Ridp::H139::RequestPrimaryDetermination, "given:
- valid JSON
- valid family params
- valid determination request params
- that encodes to XML" do

  let(:json_payload) { "{}" }

  let(:family_contract_mock) do
    instance_double(
      ::AcaEntities::Contracts::Families::FamilyContract
    )
  end

  subject do
    operation.call(json_payload)
  end

  let(:family_contract_validation_result) do
    double(
      success?: true,
      values: {}
    )
  end

  let(:family_mock) do
    instance_double(
      AcaEntities::Families::Family
    )
  end

  let(:transform_operation_mock) do
    instance_double(
      Fdsh::Ridp::H139::TransformFamilyToPrimaryDetermination
    )
  end

  let(:validation_request_mock) do
    instance_double(
      ::AcaEntities::Fdsh::Ridp::H139::PrimaryRequest
    )
  end

  let(:encoding_request_mock) do
    instance_double(
      AcaEntities::Serializers::Xml::Fdsh::Ridp::PrimaryRequest,
      to_xml: expected_xml
    )
  end

  let(:operation) do
    described_class.new
  end

  let(:expected_xml) { "<xml></xml>" }

  before :each do
    allow(::AcaEntities::Contracts::Families::FamilyContract).to receive(:new)
      .and_return(family_contract_mock)
    allow(family_contract_mock).to receive(:call).with({})
                                                 .and_return(family_contract_validation_result)
    allow(AcaEntities::Families::Family).to receive(:new).with({})
                                                         .and_return(family_mock)
    allow(Fdsh::Ridp::H139::TransformFamilyToPrimaryDetermination).to receive(:new)
      .and_return(transform_operation_mock)
    allow(transform_operation_mock).to receive(:call).with(family_mock)
                                                     .and_return(Dry::Monads::Result::Success.call(validation_request_mock))
    allow(AcaEntities::Serializers::Xml::Fdsh::Ridp::PrimaryRequest).to receive(
      :domain_to_mapper
    ).with(validation_request_mock).and_return(encoding_request_mock)

    stub_request(:post, "https://impl.hub.cms.gov/RIDPService")
      .with(
        body: "<xml></xml>",
        headers: {
          'Accept' => 'application/soap+xml',
          'Content-Type' => 'application/soap+xml',
          'Expect' => '',
          'User-Agent' => 'Faraday v1.4.3'
        }
      )
      .to_return(status: 200, body: "", headers: {})
  end

  it "succeeds" do
    expect(subject.success?).to be_truthy
  end
end