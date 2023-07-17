# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/person_cv3'

RSpec.describe Fdsh::Ssa::H3::HandleJsonSsaVerificationRequest, dbclean: :after_each do
  include_context "person hash for cv3"

  let(:correlation_id) { "SOME GENERATED CORRELATION ID" }
  let(:payload) { person_params.to_json }
  let!(:job) do
    job = FactoryBot.create(:transmittable_job)
    job.process_status = FactoryBot.create(:transmittable_process_status, statusable: job)
    job.process_status.process_states << FactoryBot.create(:transmittable_process_state)
    job.generate_message_id
    job.save
    job
  end
  let!(:transmission) do
    transmission = FactoryBot.create(:transmittable_transmission, job: job)
    transmission.process_status = FactoryBot.create(:transmittable_process_status, statusable: transmission)
    transmission.process_status.process_states << FactoryBot.create(:transmittable_process_state)
    transmission.save
    transmission
  end
  let!(:person_subject) { FactoryBot.create(:saa_person) }
  let!(:transaction) do
    transaction = person_subject.transactions.create(key: :ssa_verification, started_at: DateTime.now, json_payload: JSON.parse(payload))
    transaction.process_status = FactoryBot.create(:transmittable_process_status, statusable: transaction)
    transaction.process_status.process_states << FactoryBot.create(:transmittable_process_state)
    transaction.save
    transaction
  end
  let!(:transaction_transmission) {FactoryBot.create(:transactions_transmissions, transmission: transmission, transaction: transaction)}
  let!(:transmittable_hash)  { { message_id: job.message_id, transaction: transaction }}
  let(:mock_transmittable_payload_request) { instance_double(::Fdsh::Jobs::GenerateTransmittableSsaPayload) }
  let(:mock_transmittable_payload_response) { Dry::Monads::Result::Success.call(transmittable_hash) }
  let(:mock_jwt_request) { instance_double(::Jwt::GetJwt) }
  let(:mock_jwt_response) { Dry::Monads::Result::Success.call("3487583567384567384568") }
  let(:mock_ssa_request_verification) { instance_double(::Fdsh::Ssa::H3::RequestJsonSsaVerification) }
  let(:mock_ssa_response) { Dry::Monads::Result::Success.call(status: 200, body: "", headers: {}) }

  before :each do
    allow(::Fdsh::Jobs::GenerateTransmittableSsaPayload).to receive(:new).and_return(mock_transmittable_payload_request)
    allow(mock_transmittable_payload_request).to receive(:call).with({
                                                                       key: :ssa_verification_request,
                                                                       title: 'SSA Verification Request',
                                                                       description: 'Request for SSA verification to CMS',
                                                                       payload: payload,
                                                                       correlation_id: correlation_id,
                                                                       started_at: DateTime.now,
                                                                       publish_on: DateTime.now
                                                                     }).and_return(mock_transmittable_payload_response)
    allow(::Jwt::GetJwt).to receive(:new).and_return(mock_jwt_request)
    allow(mock_jwt_request).to receive(:call).with({}).and_return(mock_jwt_response)
    allow(::Fdsh::Ssa::H3::RequestJsonSsaVerification).to receive(:new).and_return(mock_ssa_request_verification)
    allow(mock_ssa_request_verification).to receive(:call).with({
                                                                  values: transmittable_hash,
                                                                  correlation_id: correlation_id,
                                                                  token: "3487583567384567384568"
                                                                }).and_return(mock_ssa_response)
    @result = described_class.new.call({ correlation_id: correlation_id, payload: payload })
  end

  it "is successful" do
    expect(@result.success?).to be_truthy
    expect(job.process_status.latest_state).to eq :succeeded
    expect(transmission.process_status.latest_state).to eq :succeeded
    expect(job.transmissions.count).to eq 2
  end
end