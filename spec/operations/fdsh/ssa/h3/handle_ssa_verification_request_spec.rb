# frozen_string_literal: true

require 'rails_helper'
require 'pry'

RSpec.describe Fdsh::Ssa::H3::HandleSsaVerificationRequest, "given:
  - a correlation id
  - a payload
  - the primary determination request is successful
  - contains a valid soap body in the response
  - the response can be processed" do

  let(:correlation_id) { "SOME GENERATED CORRELATION ID" }
  let(:payload) { { message: "A REQUEST PAYLOAD" } }

  let(:mock_request_operation) do
    instance_double(
      ::Fdsh::Ssa::H3::RequestSsaVerification
    )
  end

  let(:mock_response_operation) do
    instance_double(
      ::Fdsh::Ssa::H3::ProcessSsaVerificationResponse
    )
  end

  let(:mock_soap_operation) do
    instance_double(
      ::Soap::RemoveSoapEnvelope
    )
  end

  let(:request_operation_result) do
    Dry::Monads::Result::Success.call(
      instance_double(
        Faraday::Response,
        body: "SOME RESPONSE BODY"
      )
    )
  end

  let(:response_operation_result) do
    Dry::Monads::Result::Success.call(
      { message: "THE PROCESSED RESPONSE OBJECT" }
    )
  end

  let(:soap_operation_result) do
    Dry::Monads::Result::Success.call(
      "SOME EXTRACTED SOAP BODY"
    )
  end

  before :each do
    allow(::Fdsh::Ssa::H3::RequestSsaVerification).to receive(:new).and_return(
      mock_request_operation
    )
    allow(::Fdsh::Ssa::H3::ProcessSsaVerificationResponse).to receive(:new).and_return(
      mock_response_operation
    )
    allow(::Soap::RemoveSoapEnvelope).to receive(:new).and_return(
      mock_soap_operation
    )
    allow(mock_request_operation).to receive(:call).with(
      payload
    ).and_return(request_operation_result)
    allow(mock_soap_operation).to receive(:call).with(
      "SOME RESPONSE BODY"
    ).and_return(soap_operation_result)
    allow(mock_response_operation).to receive(:call).with(
      "SOME EXTRACTED SOAP BODY"
    ).and_return(response_operation_result)
  end

  subject do
    described_class.new.call({
                               correlation_id: correlation_id,
                               payload: payload
                             })
  end

  it "is successful" do
    expect(subject.success?).to be_truthy
  end
end