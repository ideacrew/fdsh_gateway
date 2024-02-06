# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/esi_transmittable'

RSpec.describe Fdsh::Esi::Rj14::HandleJsonEligibilityDeterminationRequest, dbclean: :after_each do
  include_context "esi transmittable job transmission transaction"

  let(:correlation_id) { "SOME GENERATED CORRELATION ID" }
  let!(:transmittable_hash)  { { message_id: job.message_id, transaction: transaction }}
  let(:mock_transmittable_payload_request) { instance_double(Fdsh::Jobs::GenerateTransmittableEsiPayload) }
  let(:mock_transmittable_payload_response) { Dry::Monads::Result::Success.call(transmittable_hash) }
  let(:mock_jwt_request) { instance_double(Jwt::GetJwt) }
  let(:mock_jwt_response) { Dry::Monads::Result::Success.call("3487583567384567384568") }
  let(:mock_esi_request_verification) { instance_double(Fdsh::Esi::Rj14::RequestJsonEsiDetermination) }
  let(:mock_esi_response) do
    Dry::Monads::Result::Success.call(Faraday::Response.new(status: 200, response_body: mock_esi_response_body.to_json))
  end
  let!(:mock_esi_response_body) do
    {
      esiMECResponse: {
        applicantResponseArray: [
          {
            applicantMECInformation: {
              requestedCoveragePeriod: {
                endDate: "2020-11-26",
                startDate: "2019-11-24"
              },
              inconsistencyIndicator: true
            },
            responseMetadata: {
              responseText: "Success",
              responseCode: "HS000000"
            },
            personSocialSecurityNumber: "518124854"
          }
        ]
      }
    }
  end

  before :each do
    allow(Fdsh::Jobs::GenerateTransmittableEsiPayload).to receive(:new).and_return(mock_transmittable_payload_request)
    allow(mock_transmittable_payload_request).to receive(:call).with({
                                                                       key: :esi_mec_request,
                                                                       title: 'Esi Mec Request',
                                                                       description: 'Request for esi mec for CMS',
                                                                       payload: payload,
                                                                       correlation_id: correlation_id,
                                                                       started_at: DateTime.now,
                                                                       publish_on: DateTime.now
                                                                     }).and_return(mock_transmittable_payload_response)
    allow(Jwt::GetJwt).to receive(:new).and_return(mock_jwt_request)
    allow(mock_jwt_request).to receive(:call).with({}).and_return(mock_jwt_response)
    allow(Fdsh::Esi::Rj14::RequestJsonEsiDetermination).to receive(:new).and_return(mock_esi_request_verification)
    allow(mock_esi_request_verification).to receive(:call).with({
                                                                  correlation_id: correlation_id,
                                                                  token: "3487583567384567384568",
                                                                  transmittable_objects: { transaction: transaction, transmission: transmission,
                                                                                           job: job }
                                                                }).and_return(mock_esi_response)
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
      expect(job.transmissions.pluck(:key)).to eq [:esi_mec_request, :esi_mec_response]
      expect(job.transmissions.last.transactions_transmissions.last.transaction).not_to eq nil
      expect(job.transmissions.last.transactions_transmissions.last.transaction.key).to eq :esi_mec_response
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