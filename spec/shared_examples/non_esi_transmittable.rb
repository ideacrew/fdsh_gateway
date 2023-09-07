# frozen_string_literal: true

require 'shared_examples/application_cv3'

RSpec.shared_context 'non esi transmittable job transmission transaction', shared_context: :metadata do
  include_context "application hash for cv3"
  let(:payload) { application_params.to_json }

  let!(:job) do
    job = FactoryBot.create(:transmittable_job, key: :non_esi_mec_request)
    job.process_status = FactoryBot.create(:transmittable_process_status, statusable: job)
    job.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: job.process_status)
    job.generate_message_id
    job.save
    job
  end
  let!(:transmission) do
    transmission = FactoryBot.create(:transmittable_transmission, job: job, key: :non_esi_mec_request)
    transmission.process_status = FactoryBot.create(:transmittable_process_status, statusable: transmission)
    transmission.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: transmission.process_status)
    transmission.save
    transmission
  end
  let!(:person_subject) { FactoryBot.create(:saa_person) }
  let!(:transaction) do
    transaction = person_subject.transactions.create(key: :non_esi_mec_request, started_at: DateTime.now, json_payload: JSON.parse(payload))
    transaction.process_status = FactoryBot.create(:transmittable_process_status, statusable: transaction)
    transaction.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: transaction.process_status)
    transaction.save
    transaction
  end
  let!(:transaction_transmission) {FactoryBot.create(:transactions_transmissions, transmission: transmission, transaction: transaction)}
end