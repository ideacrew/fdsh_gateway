# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/ridp_primary_transmittable'

RSpec.describe Fdsh::Ridp::Rj139::HandlePrimaryDeterminationRequest, dbclean: :after_each do
  include_context "ridp primary transmittable job transmission transaction"

  let(:correlation_id) { "SOME GENERATED CORRELATION ID" }
  let!(:transmittable_hash)  { { message_id: job.message_id, transaction: transaction }}
  let(:mock_transmittable_payload_request) { instance_double(Fdsh::Jobs::GenerateTransmittableRidpPrimaryPayload) }
  let(:mock_transmittable_payload_response) { Dry::Monads::Result::Success.call(transmittable_hash) }
  let(:mock_jwt_request) { instance_double(Jwt::GetJwt) }
  let(:mock_jwt_response) { Dry::Monads::Result::Success.call("3487583567384567384568") }
  let(:mock_primary_request_verification) { instance_double(Fdsh::Ridp::Rj139::RequestRidpPrimaryVerification) }
  let(:mock_primary_response) do
    Dry::Monads::Result::Success.call(Faraday::Response.new(status: 200, response_body: mock_primary_response_body.to_json))
  end
  let(:mock_process_response) { instance_double(Fdsh::Ridp::Rj139::ProcessPrimaryResponse) }
  let(:mock_attestation) {Dry::Monads::Result::Success.call(mock_attestation_params)}
  let(:mock_attestation_params) do
    { attestations:
  { ridp_attestation:
    { is_satisfied: true,
      is_self_attested: true,
      satisfied_at: "2024-01-04T17:54:47.337+00:00",
      evidences:
      [{ primary_response:
         { Response:
           { ResponseMetadata:
             { ResponseCode: "ABCDEFGH",
               ResponseDescriptionText: "ABCDEFGHIJKLMNOPQRSTUVWXYZA",
               TDSResponseDescriptionText: "ABCDEFGHIJKLMNOPQRSTU" },
             VerificationResponse:
             { SessionIdentification: "# Ik5/ 77RnhJ",
               DSHReferenceNumber: "ABCDEFGH",
               FinalDecisionCode: "ACC",
               VerificationQuestions:
               { VerificationQuestionSet:
                 [{ VerificationQuestionText: "ABCDEFG", VerificationAnswerChoiceText: ["ABCDEFGHIJKLMNOPQRSTUVWXYZABC"] },
                  { VerificationQuestionText: "ABCDEFGHIJKLMN", VerificationAnswerChoiceText: ["ABCDEFGHIJKLMNOPQ"] },
                  { VerificationQuestionText: "ABCD", VerificationAnswerChoiceText: ["ABCDEFGHIJKLM"] },
                  { VerificationQuestionText: "ABCDEFGHIJKLMNOP", VerificationAnswerChoiceText: ["ABCDEFGHIJKLMNOPQRSTUVWXYZAB"] },
                  { VerificationQuestionText: "ABCDEFGHIJKLMNOPQRSTUVWXYZA", VerificationAnswerChoiceText: ["ABCDEFG"] }] } } } } }],
      status: "success" } } }

  end
  let!(:mock_primary_response_body) do
    {
      ridpResponse: {
        responseMetadata: {
          responseCode: "ABCDEFGH",
          responseText: "ABCDEFGHIJKLMNOPQRSTUVWXYZA",
          tdsResponseText: "ABCDEFGHIJKLMNOPQRSTU"
        },
        sessionIdentification: "# Ik5/ 77RnhJ",
        verificationQuestionArray: [
          {
            verificationQuestionSet: {
              verificationQuestionText: "ABCDEFG",
              verificationAnswerChoiceArray: [
                {
                  verificationAnswerChoiceText: "ABCDEFGHIJKLMNOPQRSTUVWXYZABC"
                }
              ]
            }
          },
          {
            verificationQuestionSet: {
              verificationQuestionText: "ABCDEFGHIJKLMN",
              verificationAnswerChoiceArray: [
                {
                  verificationAnswerChoiceText: "ABCDEFGHIJKLMNOPQ"
                }
              ]
            }
          },
          {
            verificationQuestionSet: {
              verificationQuestionText: "ABCD",
              verificationAnswerChoiceArray: [
                {
                  verificationAnswerChoiceText: "ABCDEFGHIJKLM"
                }
              ]
            }
          },
          {
            verificationQuestionSet: {
              verificationQuestionText: "ABCDEFGHIJKLMNOP",
              verificationAnswerChoiceArray: [
                {
                  verificationAnswerChoiceText: "ABCDEFGHIJKLMNOPQRSTUVWXYZAB"
                }
              ]
            }
          },
          {
            verificationQuestionSet: {
              verificationQuestionText: "ABCDEFGHIJKLMNOPQRSTUVWXYZA",
              verificationAnswerChoiceArray: [
                {
                  verificationAnswerChoiceText: "ABCDEFG"
                }
              ]
            }
          }
        ],
        finalDecisionCode: "ACC",
        hubReferenceNumber: "ABCDEFGH"
      }
    }
  end

  before :each do
    allow(Fdsh::Jobs::GenerateTransmittableRidpPrimaryPayload).to receive(:new).and_return(mock_transmittable_payload_request)
    allow(mock_transmittable_payload_request).to receive(:call).with({
                                                                       key: :ridp_primary_verification_request,
                                                                       title: 'RIDP Primary Request',
                                                                       description: 'RIDP primary verification request to CMS',
                                                                       payload: payload,
                                                                       correlation_id: correlation_id,
                                                                       started_at: DateTime.now,
                                                                       publish_on: DateTime.now
                                                                     }).and_return(mock_transmittable_payload_response)
    allow(Jwt::GetJwt).to receive(:new).and_return(mock_jwt_request)
    allow(mock_jwt_request).to receive(:call).with({}).and_return(mock_jwt_response)
    allow(Fdsh::Ridp::Rj139::RequestRidpPrimaryVerification).to receive(:new).and_return(mock_primary_request_verification)
    allow(mock_primary_request_verification).to receive(:call).with({
                                                                      correlation_id: correlation_id,
                                                                      token: "3487583567384567384568",
                                                                      transmittable_objects: { transaction: transaction, transmission: transmission,
                                                                                               job: job }
                                                                    }).and_return(mock_primary_response)
    allow(Fdsh::Ridp::Rj139::ProcessPrimaryResponse).to receive(:new).and_return(mock_process_response)
    allow(mock_process_response).to receive(:call).with(mock_primary_response_body.deep_stringify_keys).and_return(mock_attestation)
  end

  context 'with a final descision code response' do
    before do
      @result = described_class.new.call({ correlation_id: correlation_id, payload: payload })
    end

    it "is successful" do
      expect(@result.success?).to be_truthy
      expect(job.process_status.latest_state).to eq :succeeded
      expect(transmission.process_status.latest_state).to eq :succeeded
      expect(transaction.process_status.latest_state).to eq :succeeded
      expect(job.transmissions.count).to eq 2
      expect(job.transmissions.pluck(:key)).to eq [:ridp_primary_verification_request, :ridp_primary_verification_response]
      expect(job.transmissions.last.transactions_transmissions.last.transaction).not_to eq nil
      expect(job.transmissions.last.transactions_transmissions.last.transaction.key).to eq :ridp_primary_verification_response
      expect(job.transmissions.last.transactions_transmissions.last.transaction.metadata).to eq nil
    end
  end

  context 'without a final descision code response' do
    before do
      mock_primary_response_body[:ridpResponse].delete(:finalDecisionCode)
      mock_primary_response = Dry::Monads::Result::Success.call(Faraday::Response.new(status: 200, response_body: mock_primary_response_body.to_json))
      allow(Fdsh::Ridp::Rj139::RequestRidpPrimaryVerification).to receive(:new).and_return(mock_primary_request_verification)
      allow(mock_primary_request_verification).to receive(:call).with({
                                                                        correlation_id: correlation_id,
                                                                        token: "3487583567384567384568",
                                                                        transmittable_objects: { transaction: transaction, transmission: transmission,
                                                                                                 job: job }
                                                                      }).and_return(mock_primary_response)
      allow(Fdsh::Ridp::Rj139::ProcessPrimaryResponse).to receive(:new).and_return(mock_process_response)
      allow(mock_process_response).to receive(:call).with(mock_primary_response_body.deep_stringify_keys).and_return(mock_attestation)
      @result = described_class.new.call({ correlation_id: correlation_id, payload: payload })
    end

    it "is successful" do
      expect(@result.success?).to be_truthy
      expect(job.process_status.latest_state).to eq :transmitted
      expect(job.title).to eq "RIDP Primary Request for # Ik5/ 77RnhJ"
      expect(transmission.process_status.latest_state).to eq :succeeded
      expect(transaction.process_status.latest_state).to eq :succeeded
      expect(job.transmissions.count).to eq 2
      expect(job.transmissions.pluck(:key)).to eq [:ridp_primary_verification_request, :ridp_primary_verification_response]
      expect(job.transmissions.last.transactions_transmissions.last.transaction).not_to eq nil
      expect(job.transmissions.last.transactions_transmissions.last.transaction.key).to eq :ridp_primary_verification_response
      expect(job.transmissions.last.transactions_transmissions.last.transaction.metadata).not_to eq nil
    end
  end

  context 'with a failure response' do
    it "is failure without correlation id" do
      result = described_class.new.call({ correlation_id: nil, payload: payload })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq 'Cannot process RIDP primary request without correlation id'
    end

    it "is failure without payload" do
      result = described_class.new.call({ correlation_id: correlation_id, payload: nil })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq 'Cannot process RIDP primary request without payload'
    end
  end
end