# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/ssa_transmittable'

RSpec.describe Fdsh::Ssa::H3::HandleJsonSsaVerificationRequest, dbclean: :after_each do
  include_context "ssa transmittable job transmission transaction"

  let(:correlation_id) { "SOME GENERATED CORRELATION ID" }
  let!(:transmittable_hash)  { { message_id: job.message_id, transaction: transaction }}
  let(:mock_transmittable_payload_request) { instance_double(Fdsh::Jobs::GenerateTransmittableSsaPayload) }
  let(:mock_transmittable_payload_response) { Dry::Monads::Result::Success.call(transmittable_hash) }
  let(:mock_jwt_request) { instance_double(Jwt::GetJwt) }
  let(:mock_jwt_response) { Dry::Monads::Result::Success.call("3487583567384567384568") }
  let(:mock_ssa_request_verification) { instance_double(::Fdsh::Ssa::H3::RequestJsonSsaVerification) }
  let(:mock_ssa_response) { Dry::Monads::Result::Success.call(Faraday::Response.new(status: 200, response_body: mock_ssa_response_body.to_json)) }
  let!(:mock_ssa_response_body) do
    { "ssaCompositeResponse" =>
      { "ssaCompositeIndividualResponseArray" =>
        [{ "responseMetadata" => { "responseCode" => "HS000000", "responseText" => "responseText" },
           "personSocialSecurityNumber" => "518124854",
           "ssaResponse" => { "ssnVerificationIndicator" => false } }],
        "responseMetadata" => {
          "responseText" => "responseText",
          "responseCode" => "HE123456"
        } } }
  end

  before :each do
    allow(Fdsh::Jobs::GenerateTransmittableSsaPayload).to receive(:new).and_return(mock_transmittable_payload_request)
    allow(mock_transmittable_payload_request).to receive(:call).with({
                                                                       key: :ssa_verification_request,
                                                                       title: 'SSA Verification Request',
                                                                       description: 'Request for SSA verification to CMS',
                                                                       payload: payload,
                                                                       correlation_id: correlation_id,
                                                                       started_at: DateTime.now,
                                                                       publish_on: DateTime.now
                                                                     }).and_return(mock_transmittable_payload_response)
    allow(Jwt::GetJwt).to receive(:new).and_return(mock_jwt_request)
    allow(mock_jwt_request).to receive(:call).with({}).and_return(mock_jwt_response)
    allow(Fdsh::Ssa::H3::RequestJsonSsaVerification).to receive(:new).and_return(mock_ssa_request_verification)
    allow(mock_ssa_request_verification).to receive(:call).with({
                                                                  correlation_id: correlation_id,
                                                                  token: "3487583567384567384568",
                                                                  transmittable_objects: { transaction: transaction, transmission: transmission,
                                                                                           job: job }
                                                                }).and_return(mock_ssa_response)
  end

  context 'with a successful response' do
    before do
      @result = described_class.new.call({ correlation_id: correlation_id, payload: payload })
    end

    it "is successful" do
      expect(@result.success?).to be_truthy
      expect(job.process_status.latest_state).to eq :succeeded
      expect(transmission.process_status.latest_state).to eq :succeeded
      expect(transaction.process_status.latest_state).to eq :succeeded
      expect(job.transmissions.count).to eq 2
      expect(job.transmissions.pluck(:key)).to eq [:ssa_verification_request, :ssa_verification_response]
    end
  end
end