# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::Vlp::H92::RequestInitialVerification, "given invalid JSON" do

  let(:json_payload) { "\kdslkjfe;" }

  subject do
    described_class.new.call(json_payload)
  end

  it "fails" do
    expect(subject.success?).to be_falsey
    expect(subject.failure).to eq :invalid_json
  end
end

RSpec.describe Fdsh::Vlp::H92::RequestInitialVerification, "given:
- valid JSON
- invalid person params" do

  let(:json_payload) { "{}" }

  let(:person_contract_mock) do
    instance_double(
      AcaEntities::Contracts::People::PersonContract
    )
  end

  subject do
    described_class.new.call(json_payload)
  end

  let(:person_contract_validation_result) do
    double(
      success?: false,
      errors: :invalid_person
    )
  end

  before :each do
    allow(AcaEntities::Contracts::People::PersonContract).to receive(:new)
      .and_return(person_contract_mock)
    allow(person_contract_mock).to receive(:call).with({})
                                                 .and_return(person_contract_validation_result)
  end

  it "fails" do
    expect(subject.success?).to be_falsey
    expect(subject.failure).to eq :invalid_person
  end
end

RSpec.describe Fdsh::Vlp::H92::RequestInitialVerification, "given:
- valid JSON
- valid person params
- invalid determination request params" do

  let(:json_payload) { "{}" }

  let(:person_contract_mock) do
    instance_double(
      AcaEntities::Contracts::People::PersonContract
    )
  end

  subject do
    described_class.new.call(json_payload)
  end

  let(:person_contract_validation_result) do
    double(
      success?: true,
      values: {}
    )
  end

  let(:person_mock) do
    instance_double(
      AcaEntities::People::Person
    )
  end

  let(:transform_operation_mock) do
    instance_double(
      Fdsh::Vlp::H92::TransformPersonToInitialRequest
    )
  end

  before :each do
    allow(AcaEntities::Contracts::People::PersonContract).to receive(:new)
      .and_return(person_contract_mock)
    allow(person_contract_mock).to receive(:call).with({})
                                                 .and_return(person_contract_validation_result)
    allow(AcaEntities::People::Person).to receive(:new).with({})
                                                       .and_return(person_mock)
    allow(Fdsh::Vlp::H92::TransformPersonToInitialRequest).to receive(:new)
      .and_return(transform_operation_mock)
    allow(transform_operation_mock).to receive(:call).with(person_mock)
                                                     .and_return(Dry::Monads::Result::Failure.call(nil))
  end

  it "fails" do
    expect(subject.success?).to be_falsey
  end
end

RSpec.describe Fdsh::Vlp::H92::RequestInitialVerification, "given:
- valid JSON
- valid person params
- valid determination request params
- that encodes to XML" do

  let(:json_payload) { "{}" }

  let(:person_contract_mock) do
    instance_double(
      AcaEntities::Contracts::People::PersonContract
    )
  end

  subject do
    operation.call(json_payload)
  end

  let(:person_contract_validation_result) do
    double(
      success?: true,
      values: {}
    )
  end

  let(:person_mock) do
    instance_double(
      AcaEntities::People::Person
    )
  end

  let(:transform_operation_mock) do
    instance_double(
      Fdsh::Vlp::H92::TransformPersonToInitialRequest
    )
  end

  let(:validation_request_mock) do
    instance_double(
      AcaEntities::Fdsh::Vlp::H92::InitialVerificationRequest
    )
  end

  let(:encoding_request_mock) do
    instance_double(
      AcaEntities::Serializers::Xml::Fdsh::Vlp::H92::Operations::InitialRequestToXml
    )
  end

  let(:operation) do
    described_class.new
  end

  let(:expected_xml) { "<xml xmlns=\"uri:whatever\"></xml>" }

  before :each do
    allow(AcaEntities::Contracts::People::PersonContract).to receive(:new)
      .and_return(person_contract_mock)
    allow(person_contract_mock).to receive(:call).with({})
                                                 .and_return(person_contract_validation_result)
    allow(AcaEntities::People::Person).to receive(:new).with({})
                                                       .and_return(person_mock)
    allow(Fdsh::Vlp::H92::TransformPersonToInitialRequest).to receive(:new)
      .and_return(transform_operation_mock)
    allow(transform_operation_mock).to receive(:call).with(person_mock)
                                                     .and_return(Dry::Monads::Result::Success.call(validation_request_mock))
    allow(AcaEntities::Serializers::Xml::Fdsh::Vlp::H92::Operations::InitialRequestToXml).to receive(
      :new
    ).and_return(encoding_request_mock)
    allow(encoding_request_mock).to receive(
      :call
    ).with(validation_request_mock).and_return(Dry::Monads::Result::Success.call(expected_xml))

    stub_request(:post, "https://impl.hub.cms.gov/Imp1/VerifyLawfulPresenceServiceV37")
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