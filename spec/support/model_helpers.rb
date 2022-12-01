# frozen_string_literal: true

# Helper method to create transaction and activities
module ModelHelpers

  # this is the default, set to RRV for historical reasons
  def create_transaction_store_request(applications)
    create_transaction_store_request_proxy(applications, :rrv_hash)
  end

  def create_transaction_store_request_pvc(applications)
    create_transaction_store_request_proxy(applications, :pvc_hash)
  end

  def create_transaction_store_request_proxy(applications, hash_resolver)
    applications.each do |application|
      application.applicants.each do |applicant|
        activity_hash = method(hash_resolver).call("request", application, applicant)
        create_or_update_transaction("request", application, applicant, activity_hash)
      end
    end
  end

  def rrv_hash(key, value, applicant)
    activity_hash = {
      correlation_id: "rrv_mdcr_#{applicant.identifying_information.encrypted_ssn}",
      command: "Fdsh::Rrv::Medicare::BuildMedicareRequestXml",
      event_key: "rrv_mdcr_determination_requested",
      message: { "#{key}": value.to_h }
    }
  end

  def pvc_hash(key, value, applicant)
    activity_hash = {
      correlation_id: "pvc_mdcr_#{applicant.identifying_information.encrypted_ssn}",
      command: "Fdsh::Pvc::Medicare::BuildMedicareRequestXml",
      event_key: "pvc_mdcr_determination_requested",
      message: { "#{key}": value.to_h }
    }
  end

  def create_or_update_transaction(key, value, applicant, activity_hash)
    application = value.to_h # in case value is an AcaEntities entity
    primary_hbx_id = application[:applicants].detect {|a| a[:is_primary_applicant]}&.dig(:person_hbx_id)
    transaction_hash = {
      correlation_id: activity_hash[:correlation_id],
      activity: activity_hash,
      magi_medicaid_application: value.to_json,
      application_id: application[:hbx_id],
      primary_hbx_id: primary_hbx_id
    }
    Journal::Transactions::AddActivity.new.call(transaction_hash).value!
  end
end