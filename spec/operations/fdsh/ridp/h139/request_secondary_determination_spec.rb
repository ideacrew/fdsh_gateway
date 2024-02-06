# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::Ridp::H139::RequestSecondaryDetermination, "given invalid JSON" do

  let(:json_payload) { "\kdslkjfe;" }

  subject do
    described_class.new.call(json_payload)
  end

  it "fails" do
    expect(subject.success?).to be_falsey
    expect(subject.failure).to eq :invalid_json
  end
end

RSpec.describe Fdsh::Ridp::H139::RequestSecondaryDetermination, "given:
- valid JSON
- invalid family params" do

  let(:json_payload) { "{}" }

  let(:family_contract_mock) do
    instance_double(
      AcaEntities::Contracts::Families::FamilyContract
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
    allow(AcaEntities::Contracts::Families::FamilyContract).to receive(:new)
      .and_return(family_contract_mock)
    allow(family_contract_mock).to receive(:call).with({})
                                                 .and_return(family_contract_validation_result)
  end

  it "fails" do
    expect(subject.success?).to be_falsey
    expect(subject.failure).to eq :invalid_family
  end
end

RSpec.describe Fdsh::Ridp::H139::RequestSecondaryDetermination, "given:
- valid JSON
- valid family params
- invalid determination request params" do

  let(:json_payload) { "{}" }

  let(:family_contract_mock) do
    instance_double(
      AcaEntities::Contracts::Families::FamilyContract
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
      Fdsh::Ridp::H139::TransformFamilyToSecondaryDetermination
    )
  end

  before :each do
    allow(AcaEntities::Contracts::Families::FamilyContract).to receive(:new)
      .and_return(family_contract_mock)
    allow(family_contract_mock).to receive(:call).with({})
                                                 .and_return(family_contract_validation_result)
    allow(AcaEntities::Families::Family).to receive(:new).with({})
                                                         .and_return(family_mock)
    allow(Fdsh::Ridp::H139::TransformFamilyToSecondaryDetermination).to receive(:new)
      .and_return(transform_operation_mock)
    allow(transform_operation_mock).to receive(:call).with(family_mock)
                                                     .and_return(Dry::Monads::Result::Failure.call(nil))
  end

  it "fails" do
    expect(subject.success?).to be_falsey
  end
end

RSpec.describe Fdsh::Ridp::H139::RequestSecondaryDetermination, "given:
- valid JSON
- valid family params
- valid determination request params
- that encodes to XML" do

  let(:json_payload) { "{}" }

  let(:family_contract_mock) do
    instance_double(
      AcaEntities::Contracts::Families::FamilyContract
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
      Fdsh::Ridp::H139::TransformFamilyToSecondaryDetermination
    )
  end

  let(:validation_request_mock) do
    instance_double(
      AcaEntities::Fdsh::Ridp::H139::PrimaryRequest
    )
  end

  let(:encoding_request_mock) do
    instance_double(
      AcaEntities::Serializers::Xml::Fdsh::Ridp::Operations::PrimaryRequestToXml
    )
  end

  let(:operation) do
    described_class.new
  end

  let(:expected_xml) { "<xml></xml>" }

  before :each do
    allow(AcaEntities::Contracts::Families::FamilyContract).to receive(:new)
      .and_return(family_contract_mock)
    allow(family_contract_mock).to receive(:call).with({})
                                                 .and_return(family_contract_validation_result)
    allow(AcaEntities::Families::Family).to receive(:new).with({})
                                                         .and_return(family_mock)
    allow(Fdsh::Ridp::H139::TransformFamilyToSecondaryDetermination).to receive(:new)
      .and_return(transform_operation_mock)
    allow(transform_operation_mock).to receive(:call).with(family_mock)
                                                     .and_return(Dry::Monads::Result::Success.call(validation_request_mock))
    allow(AcaEntities::Serializers::Xml::Fdsh::Ridp::Operations::SecondaryRequestToXml).to receive(
      :new
    ).and_return(encoding_request_mock)
    allow(encoding_request_mock).to receive(
      :call
    ).with(validation_request_mock).and_return(Dry::Monads::Result::Success.call(expected_xml))

    stub_request(:post, "https://impl.hub.cms.gov/Imp1/RIDPService")
      .with(
        headers: {
          'Accept' => 'application/soap+xml',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/soap+xml',
          'User-Agent' => 'Faraday v1.4.3'
        }
      ) do |_request|
        true
      end.to_return(status: 200, body: "", headers: {})
  end

  it "succeeds" do
    expect(subject.success?).to be_truthy
  end
end