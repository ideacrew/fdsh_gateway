# frozen_string_literal: true

require 'shared_examples/person_cv3'

RSpec.shared_context 'vlp transmittable job transmission transaction', shared_context: :metadata do
  include_context "person hash for cv3"
  let(:payload) { person_params.to_json }
  let(:correlation_id) { "SOME GENERATED CORRELATION ID" }

  let!(:job) do
    job = FactoryBot.create(:transmittable_job, key: :vlp_verification_request, started_at: DateTime.now)
    job.process_status = FactoryBot.create(:transmittable_process_status, statusable: job)
    job.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: job.process_status)
    job.generate_message_id
    job.save
    job
  end
  let!(:transmission) do
    transmission = FactoryBot.create(:transmittable_transmission, job: job, key: :vlp_verification_request, started_at: DateTime.now)
    transmission.process_status = FactoryBot.create(:transmittable_process_status, statusable: transmission)
    transmission.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: transmission.process_status)
    transmission.save
    transmission
  end
  let!(:person_subject) do
    Transmittable::Person.create(correlation_id: "test_person_123",
                                 hbx_id: "12348",
                                 encrypted_ssn: "jsabcsdinc",
                                 surname: "last_name",
                                 given_name: "First_name",
                                 dob: "2020-01-01")
  end
  let!(:transaction) do
    transaction = person_subject.transactions.create(key: :vlp_verification_request, started_at: DateTime.now, xml_payload: "<xmlstring></xmlstring>")
    transaction.process_status = FactoryBot.create(:transmittable_process_status, statusable: transaction)
    transaction.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: transaction.process_status)
    transaction.save
    transaction
  end
  let!(:transaction_transmission) {FactoryBot.create(:transactions_transmissions, transmission: transmission, transaction: transaction)}
end