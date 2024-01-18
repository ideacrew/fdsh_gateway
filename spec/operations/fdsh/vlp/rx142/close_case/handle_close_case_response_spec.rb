# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/vlp_transmittable'

RSpec.describe Fdsh::Vlp::Rx142::CloseCase::HandleCloseCaseRequest do
  include_context 'vlp transmittable job transmission transaction'

  let(:case_number) { '0024012180322QQ' }
  let(:file) do
    loc = File.join(Rails.root, "spec", "reference", "xml", "vlp", "rx142", "close_case", "CloseCaseResponse.xml")
    File.expand_path(loc)
  end
  let(:xml_content) { File.open(file) }

  let!(:transmittable_hash)  { { message_id: job.message_id, transaction: transaction }}
  let(:mock_transmittable_payload_request) { instance_double(::Fdsh::Jobs::Vlp::GenerateTransmittableCloseCasePayload) }
  let(:mock_transmittable_payload_response) { Dry::Monads::Result::Success.call(transmittable_hash) }
  let(:mock_jwt_request) { instance_double(Jwt::GetJwt) }
  let(:mock_jwt_response) { Dry::Monads::Result::Success.call("3487583567384567384568") }
  let(:mock_vlp_request_close_case) { instance_double(::Fdsh::Vlp::Rx142::CloseCase::RequestCloseCase) }
  let(:mock_close_case_response) do
    Dry::Monads::Result::Success.call(Faraday::Response.new(status: 200, response_body: xml_content))
  end

  before do
    allow(::Fdsh::Jobs::Vlp::GenerateTransmittableCloseCasePayload).to receive(:new).and_return(mock_transmittable_payload_request)
    allow(mock_transmittable_payload_request).to receive(:call).with({
                                                                       key: :vlp_close_case_request,
                                                                       title: 'VLP Close Case Request',
                                                                       description: 'Request VLP Close Case from CMS',
                                                                       payload: payload,
                                                                       correlation_id: correlation_id,
                                                                       case_number: case_number,
                                                                       started_at: DateTime.now,
                                                                       publish_on: DateTime.now
                                                                     }).and_return(mock_transmittable_payload_response)
    allow(Jwt::GetJwt).to receive(:new).and_return(mock_jwt_request)
    allow(mock_jwt_request).to receive(:call).with({}).and_return(mock_jwt_response)
    allow(Fdsh::Vlp::Rx142::CloseCase::RequestCloseCase).to receive(:new).and_return(mock_vlp_request_close_case)
    allow(mock_vlp_request_close_case).to receive(:call).with({
                                                                correlation_id: correlation_id,
                                                                token: "3487583567384567384568",
                                                                transmittable_objects: { transaction: transaction, transmission: transmission,
                                                                                         job: job }
                                                              }).and_return(mock_close_case_response)
  end

  subject do
    described_class.new.call({
                               case_number: case_number,
                               correlation_id: correlation_id,
                               payload: payload
                             })
  end

  it "is successful" do
    expect(subject.success?).to be_truthy
  end
end