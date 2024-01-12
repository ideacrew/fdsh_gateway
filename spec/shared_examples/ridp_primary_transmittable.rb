# frozen_string_literal: true

require 'shared_examples/family_response2'

RSpec.shared_context 'ridp primary transmittable job transmission transaction', shared_context: :metadata do
  include_context "family response with one policy"
  let(:payload) { family_hash.to_json }

  let!(:job) do
    job = FactoryBot.create(:transmittable_job, key: :ridp_verification_request)
    job.process_status = FactoryBot.create(:transmittable_process_status, statusable: job)
    job.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: job.process_status)
    job.generate_message_id
    job.save
    job
  end
  let!(:transmission) do
    transmission = FactoryBot.create(:transmittable_transmission, job: job, key: :ridp_primary_verification_request)
    transmission.process_status = FactoryBot.create(:transmittable_process_status, statusable: transmission)
    transmission.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: transmission.process_status)
    transmission.save
    transmission
  end
  let!(:person_subject) { FactoryBot.create(:transmittable_person) }
  let!(:transaction) do
    transaction = person_subject.transactions.create(key: :ridp_primary_verification_request, started_at: DateTime.now,
                                                     json_payload: JSON.parse(payload))
    transaction.process_status = FactoryBot.create(:transmittable_process_status, statusable: transaction)
    transaction.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: transaction.process_status)
    transaction.save
    transaction
  end
  let!(:transaction_transmission) {FactoryBot.create(:transactions_transmissions, transmission: transmission, transaction: transaction)}
end