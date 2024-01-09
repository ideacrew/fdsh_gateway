# frozen_string_literal: true

require 'rails_helper'
require 'pry'
require 'shared_examples/vlp_transmittable'
require 'shared_examples/person_cv3'

RSpec.describe Fdsh::Vlp::Rx142::InitialVerification::HandleInitialVerificationRequest, "given:
  - a correlation id
  - a payload
  - the primary determination request is successful
  - contains a valid xml body in the response
  - the response can be processed" do
  include_context "vlp transmittable job transmission transaction"
  include_context "person hash for cv3"

  let(:correlation_id) { "SOME GENERATED CORRELATION ID" }
  let(:payload) { person_params.to_json }
  let(:file) do
    loc = File.join(Rails.root, "spec", "reference", "xml", "vlp", "initial_verification", "InitialVerificationResponse.xml")
    File.expand_path(loc)
  end

  let(:xml) {File.open(file)}

  let!(:transmittable_hash)  { { message_id: job.message_id, transaction: transaction }}
  let(:mock_transmittable_payload_request) { instance_double(::Fdsh::Jobs::Vlp::GenerateTransmittableInitialVerificationPayload) }
  let(:mock_transmittable_payload_response) { Dry::Monads::Result::Success.call(transmittable_hash) }
  let(:mock_jwt_request) { instance_double(Jwt::GetJwt) }
  let(:mock_jwt_response) { Dry::Monads::Result::Success.call("3487583567384567384568") }
  let(:mock_vlp_request_verification) { instance_double(::Fdsh::Vlp::Rx142::InitialVerification::RequestVlpVerification) }

  let(:mock_vlp_response) do
    Dry::Monads::Result::Success.call(Faraday::Response.new(status: 200, response_body: xml))
  end
  before :each do
    allow(::Fdsh::Jobs::Vlp::GenerateTransmittableInitialVerificationPayload).to receive(:new).and_return(mock_transmittable_payload_request)
    allow(mock_transmittable_payload_request).to receive(:call).with({
                                                                       key: :vlp_verification_request,
                                                                       title: 'VLP Verification Request',
                                                                       description: 'Request for VLP verification to CMS',
                                                                       payload: payload,
                                                                       correlation_id: correlation_id,
                                                                       started_at: DateTime.now,
                                                                       publish_on: DateTime.now
                                                                     }).and_return(mock_transmittable_payload_response)
    allow(Jwt::GetJwt).to receive(:new).and_return(mock_jwt_request)
    allow(mock_jwt_request).to receive(:call).with({}).and_return(mock_jwt_response)
    allow(Fdsh::Vlp::Rx142::InitialVerification::RequestVlpVerification).to receive(:new).and_return(mock_vlp_request_verification)
    allow(mock_vlp_request_verification).to receive(:call).with({
                                                                  correlation_id: correlation_id,
                                                                  token: "3487583567384567384568",
                                                                  transmittable_objects: { transaction: transaction, transmission: transmission,
                                                                                           job: job }
                                                                }).and_return(mock_vlp_response)

    described_class.new.call({
      correlation_id: correlation_id,
      payload: payload
    })
  end

  it "is successful" do
    binding.irb
    expect(subject.success?).to be_truthy
  end
end
