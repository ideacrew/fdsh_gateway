# frozen_string_literal: true

# Helper method to create transaction and activities
module ModelHelpers
  def create_transaction_store_request(applications)
    applications.each do |application|
      application.applicants.each do |applicant|
        create_or_update_transaction("request", application, applicant)
      end
    end
  end

  def create_or_update_transaction(key, value, applicant)
    activity_hash = {
      correlation_id: "rrv_mdcr_#{applicant.identifying_information.encrypted_ssn}",
      command: "Fdsh::Rrv::Medicare::BuildMedicareRequestXml",
      event_key: "rrv_mdcr_determination_requested",
      message: { "#{key}": value.to_h }
    }

    transaction_hash = { correlation_id: activity_hash[:correlation_id], magi_medicaid_application: value.to_json,
                         activity: activity_hash }
    Journal::Transactions::AddActivity.new.call(transaction_hash).value!
  end
end