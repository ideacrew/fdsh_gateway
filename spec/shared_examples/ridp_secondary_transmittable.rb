# frozen_string_literal: true

RSpec.shared_context 'ridp secondary transmittable job transmission transaction', shared_context: :metadata do
  let(:payload) do
    { :ridpRequest =>
  { :secondaryRequest =>
    { :verificationAnswerArray =>
      [{ :verificationAnswerSet => { :verificationAnswer => "1", :verificationQuestionNumber => "1" } },
       { :verificationAnswerSet => { :verificationAnswer => "1", :verificationQuestionNumber => "2" } },
       { :verificationAnswerSet => { :verificationAnswer => "2", :verificationQuestionNumber => "3" } }],
      :sessionIdentification => "SESSION1",
      :hubReferenceNumber => "TRANSMISSION1" } } }
  end

  let!(:job) do
    job = FactoryBot.create(:transmittable_job, key: :ridp_verification_request)
    job.process_status = FactoryBot.create(:transmittable_process_status, statusable: job)
    job.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: job.process_status)
    job.generate_message_id
    job.save
    job
  end
  let!(:transmission) do
    transmission = FactoryBot.create(:transmittable_transmission, job: job, key: :ridp_secondary_verification_request)
    transmission.process_status = FactoryBot.create(:transmittable_process_status, statusable: transmission)
    transmission.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: transmission.process_status)
    transmission.save
    transmission
  end
  let!(:person_subject) { FactoryBot.create(:transmittable_person) }
  let!(:transaction) do
    transaction = person_subject.transactions.create(key: :ridp_secondary_verification_request, started_at: DateTime.now,
                                                     json_payload: payload)
    transaction.process_status = FactoryBot.create(:transmittable_process_status, statusable: transaction)
    transaction.process_status.process_states << FactoryBot.create(:transmittable_process_state, process_status: transaction.process_status)
    transaction.save
    transaction
  end
  let!(:transaction_transmission) {FactoryBot.create(:transactions_transmissions, transmission: transmission, transaction: transaction)}
end