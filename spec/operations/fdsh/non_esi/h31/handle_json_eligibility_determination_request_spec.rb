# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/non_esi_transmittable'

RSpec.describe Fdsh::NonEsi::H31::HandleJsonEligibilityDeterminationRequest, dbclean: :after_each do
  include_context "non esi transmittable job transmission transaction"

  let(:correlation_id) { "SOME GENERATED CORRELATION ID" }
  let!(:transmittable_hash)  { { message_id: job.message_id, transaction: transaction }}
  let(:mock_transmittable_payload_request) { instance_double(Fdsh::Jobs::GenerateTransmittableNonEsiPayload) }
  let(:mock_transmittable_payload_response) { Dry::Monads::Result::Success.call(transmittable_hash) }
  let(:mock_jwt_request) { instance_double(Jwt::GetJwt) }
  let(:mock_jwt_response) { Dry::Monads::Result::Success.call("3487583567384567384568") }
  let(:mock_non_esi_request_verification) { instance_double(::Fdsh::NonEsi::H31::RequestJsonNonEsiDetermination) }
  let(:mock_non_esi_response) do
    Dry::Monads::Result::Success.call(Faraday::Response.new(status: 200, response_body: mock_non_esi_response_body.to_json))
  end
  let!(:mock_non_esi_response_body) do
    {
      verifyNonESIMECResponse: {
        individualResponseArray: [
          {
            partialResponseIndicator: false,
            personSurName: "evidence",
            personBirthDate: "1988-11-11",
            otherCoverageArray: [
              {
                organizationCode: "VHPC",
                responseMetadata: {
                  responseText: "Success",
                  responseCode: "HE000000"
                }
              }
            ],
            personSocialSecurityNumber: "518124854",
            personGivenName: "esi"
          }
        ]
      }
    }
  end

  before :each do
    allow(Fdsh::Jobs::GenerateTransmittableNonEsiPayload).to receive(:new).and_return(mock_transmittable_payload_request)
    allow(mock_transmittable_payload_request).to receive(:call).with({
                                                                       key: :non_esi_mec_request,
                                                                       title: 'Non Esi Mec Request',
                                                                       description: 'Request for Non esi mec for CMS',
                                                                       payload: payload,
                                                                       correlation_id: correlation_id,
                                                                       started_at: DateTime.now,
                                                                       publish_on: DateTime.now
                                                                     }).and_return(mock_transmittable_payload_response)
    allow(Jwt::GetJwt).to receive(:new).and_return(mock_jwt_request)
    allow(mock_jwt_request).to receive(:call).with({}).and_return(mock_jwt_response)
    allow(Fdsh::NonEsi::H31::RequestJsonNonEsiDetermination).to receive(:new).and_return(mock_non_esi_request_verification)
    allow(mock_non_esi_request_verification).to receive(:call).with({
                                                                      correlation_id: correlation_id,
                                                                      token: "3487583567384567384568",
                                                                      transmittable_objects: { transaction: transaction, transmission: transmission,
                                                                                               job: job }
                                                                    }).and_return(mock_non_esi_response)
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
      expect(job.transmissions.pluck(:key)).to eq [:non_esi_mec_request, :non_esi_mec_response]
      expect(job.transmissions.last.transactions_transmissions.last.transaction).not_to eq nil
      expect(job.transmissions.last.transactions_transmissions.last.transaction.key).to eq :non_esi_mec_response
    end
  end

  context 'with a failure response' do
    it "is failure without correlation id" do
      result = described_class.new.call({ correlation_id: nil, payload: payload })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq 'Cannot process eligibility determination request without correlation id'
    end

    it "is failure without payload" do
      result = described_class.new.call({ correlation_id: correlation_id, payload: nil })
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq 'Cannot process eligibility determination request without payload'
    end
  end
end