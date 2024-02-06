# frozen_string_literal: true

require 'rails_helper'
require 'pry'
require 'shared_examples/application_cv3'

RSpec.describe Fdsh::NonEsi::H31::HandleEligibilityDeterminationRequest, "given:
  - a correlation id
  - a payload
  - the primary determination request is successful
  - contains a valid soap body in the response
  - the response can be processed", dbclean: :after_each do
  include_context "application hash for cv3"

  let(:params) do
    {
      correlation_id: correlation_id,
      payload: application_params.to_json,
      event_key: event_key
    }
  end

  let(:application) do
    AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(application_params).value!
  end

  let(:correlation_id) { "SOME GENERATED CORRELATION ID" }
  let(:event_key) { "EVENT KEY" }

  let(:mock_request_operation) do
    instance_double(
      Fdsh::NonEsi::H31::RequestNonEsiDetermination
    )
  end

  let(:mock_response_operation) do
    instance_double(
      Fdsh::NonEsi::H31::ProcessNonEsiDeterminationResponse
    )
  end

  let(:mock_update_application_response_operation) do
    instance_double(
      Fdsh::NonEsi::H31::UpdateApplicationWithResponse
    )
  end

  let(:mock_soap_operation) do
    instance_double(
      Soap::RemoveSoapEnvelope
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

  let(:updated_application_with_response_result) do
    Dry::Monads::Result::Success.call(
      { application: "updated application" }
    )
  end

  let(:soap_operation_result) do
    Dry::Monads::Result::Success.call(
      "SOME EXTRACTED SOAP BODY"
    )
  end

  before :each do
    allow(Fdsh::NonEsi::H31::RequestNonEsiDetermination).to receive(:new).and_return(
      mock_request_operation
    )
    allow(Fdsh::NonEsi::H31::ProcessNonEsiDeterminationResponse).to receive(:new).and_return(
      mock_response_operation
    )
    allow(Soap::RemoveSoapEnvelope).to receive(:new).and_return(
      mock_soap_operation
    )
    allow(Fdsh::NonEsi::H31::UpdateApplicationWithResponse).to receive(:new).and_return(
      mock_update_application_response_operation
    )
    allow(mock_request_operation).to receive(:call).with(
      application, params
    ).and_return(request_operation_result)
    allow(mock_soap_operation).to receive(:call).with(
      "SOME RESPONSE BODY"
    ).and_return(soap_operation_result)
    allow(mock_response_operation).to receive(:call).with(
      "SOME EXTRACTED SOAP BODY", params
    ).and_return(response_operation_result)

    allow(mock_update_application_response_operation).to receive(:call).with(
      application, response_operation_result.value!, correlation_id
    ).and_return(updated_application_with_response_result)
  end

  subject do
    described_class.new.call(params)
  end

  it "is successful" do
    expect(subject.success?).to be_truthy
  end
end