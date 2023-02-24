# frozen_string_literal: true

# This script updates Transactions that are already transmitted to CMS and
# creates TransmissionPath objects for transmitted transactions
# bundle exec rails runner script/handle_transmitted_transactions.rb

# Before we run this script, we need to upload CMS folder named "SBE00ME.DSH.EOYIN.D230210.T214339000.P.IN.SUBMIT.20230210" at the root

require 'csv'

def create_h41_open_transmission(transmission_type, reporting_year)
  ::Fdsh::H41::Transmissions::FindOrCreate.new.call(
    {
      reporting_year: reporting_year,
      status: :open,
      transmission_type: transmission_type
    }
  ).success
end

def find_and_update_h41_open_transmission(transmission_type, reporting_year)
  transmission = find_h41_transmission(transmission_type, reporting_year, :open)
  transmission.update_attributes!(status: :transmitted)
  transmission
end

def find_old_original_transmission(transmission_type, reporting_year)
  find_h41_transmission(transmission_type, reporting_year, :transmitted) || find_and_update_h41_open_transmission(transmission_type, reporting_year)
end

def find_h41_original_transmissions
  @old_original_transmission = find_old_original_transmission(:original, 2022)
  @original_transmission = create_h41_open_transmission(:original, 2022)
end

def find_h41_transmission(transmission_type, reporting_year, status)
  ::Fdsh::H41::Transmissions::Find.new.call(
    {
      reporting_year: reporting_year,
      status: status,
      transmission_type: transmission_type
    }
  ).success
end

def process_h41_transactions
  @all_file_paths = Dir["#{Rails.root}/SBE00ME.DSH.EOYIN.D230210.T214339000.P.IN.SUBMIT.20230210/*.xml"]
  @file_name = "#{Rails.root}/handle_transmitted_transactions_#{Date.today.strftime('%Y_%m_%d')}.csv"
  @field_names = %w[
    h41_transaction_primary_hbx_id
    h41_transaction_family_hbx_id
    h41_transaction_policy_hbx_id
    posted_family_primary_hbx_id
    posted_family_family_hbx_id
    insurance_policy_hbx_id
    insurance_policy_assistance_year
    aptc_csr_thh_hbx_assigned_id
    posted_family_transmission_path
  ]
  @counter = 0
  @eligible_h41_transactions = H41Transaction.all.non_migrated
  @eligible_h41_transactions = H41Transaction.where(
    :policy_hbx_id.in => ::Transmittable::Transaction.where(
      transactable_type: 'H41::InsurancePolicies::AptcCsrTaxHousehold'
    ).map(&:transactable).flat_map(&:insurance_policy).flat_map(&:policy_hbx_id)
  )
  find_h41_original_transmissions
  update_transmitted_transactions
rescue StandardError => e
  @logger.info "Error raised message: #{e}, backtrace: #{e.backtrace}"
end

def fetch_transmission_path_attrs_single_thh(policy_hbx_id)
  expected_file_path = find_content_file_path(policy_hbx_id)
  record_sequence_element_start = '<airty20a:RecordSequenceNum>'
  record_sequence_element_end = '</airty20a:RecordSequenceNum>'
  record_sequence_num_extention = @content_file_xml_string[/#{record_sequence_element_start}#{policy_hbx_id}(.*?)#{record_sequence_element_end}/m, 1]
  [policy_hbx_id + record_sequence_num_extention, File.basename(expected_file_path).split('_')[2]]
end

def find_content_file_path(policy_hbx_id)
  market_place_policy_num_start_ele = '<airty20a:MarketPlacePolicyNum>'
  market_place_policy_num_end_ele = '</airty20a:MarketPlacePolicyNum>'
  market_place_policy_snippet = "#{market_place_policy_num_start_ele}#{policy_hbx_id}#{market_place_policy_num_end_ele}"

  @all_file_paths.each do |file_path|
    @content_file_xml_string = File.read(file_path)
    return file_path if @content_file_xml_string.match?(market_place_policy_snippet)
  end

  nil
end

def fetch_transmission_path_attrs(old_transaction, aptc_csr_tax_household, policy)
  if old_transaction.aptc_csr_tax_households.count == 1
    fetch_transmission_path_attrs_single_thh(policy.policy_hbx_id)
  else
    expected_file_path = find_content_file_path(policy.policy_hbx_id)
    return [nil, nil] if expected_file_path.nil?

    xml_doc = Nokogiri::XML(@content_file_xml_string)
    xml_doc.xpath("//airty20a:Form1095AUpstreamDetail").detect do |node|
      @record_sequence_number = node.xpath('//airty20a:RecordSequenceNum').text
      polict_id = node.xpath('//airty20a:Policy/airty20a:MarketPlacePolicyNum').text

      policy.policy_hbx_id == polict_id && matching_thh_info?(node, aptc_csr_tax_household)
    end

    [@record_sequence_number, File.basename(expected_file_path).split('_')[2]]
  end
end

def matching_thh_info?(node, aptc_csr_tax_household)
  content_recipient_ssn = node.xpath('//airty20a:Recipient/irs:SSN').text
  thh_node = Nokogiri::XML(aptc_csr_tax_household.transaction_xml).xpath("batchreq:Form1095ATransmissionUpstream").first
  recipient_ssn = thh_node.xpath('//airty20a:Recipient/irs:SSN').text
  return true if content_recipient_ssn.present? && content_recipient_ssn == recipient_ssn

  content_recipient_dob = node.xpath('//airty20a:Recipient/airty20a:BirthDt').text
  content_recipient_fn = node.xpath('//airty20a:Recipient/airty20a:OtherCompletePersonName/airty20a:PersonFirstNm').text
  content_recipient_ln = node.xpath('//airty20a:Recipient/airty20a:OtherCompletePersonName/airty20a:PersonLastNm').text

  recipient_dob = thh_node.xpath('//airty20a:Recipient/airty20a:BirthDt').text
  recipient_fn = thh_node.xpath('//airty20a:Recipient/airty20a:OtherCompletePersonName/airty20a:PersonFirstNm').text
  recipient_ln = thh_node.xpath('//airty20a:Recipient/airty20a:OtherCompletePersonName/airty20a:PersonLastNm').text

  content_recipient_dob == recipient_dob && content_recipient_fn == recipient_fn && content_recipient_ln == recipient_ln
end

# rubocop:disable Metrics
def update_transmitted_transactions
  CSV.open(@file_name, 'w', force_quotes: true) do |csv|
    csv << @field_names
    @logger.info "Total number of non_migrated H41Transactions: #{@eligible_h41_transactions.count}"
    @eligible_h41_transactions.no_timeout.each do |old_transaction|
      @counter += 1
      @logger.info "---------- Processed #{@counter} of old_transactions" if @counter % 1000 == 0
      @logger.info "----- Processing H41Transaction FamilyHbxID: #{old_transaction.family_hbx_id}"
      policy = ::H41::InsurancePolicies::InsurancePolicy.where(policy_hbx_id: old_transaction.policy_hbx_id).first
      posted_family = policy.posted_family
      policy.aptc_csr_tax_households.each do |aptc_csr_tax_household|
        aptc_csr_tax_household.transactions.each do |transaction|
          record_sequence_num, file_id = fetch_transmission_path_attrs(old_transaction, aptc_csr_tax_household, policy)

          if record_sequence_num.blank? || file_id.blank?
            @logger.info "Could not find record_sequence_num & file_id for old_transaction policy_hbx_id: #{
              old_transaction.policy_hbx_id}, primary_hbx_id: #{old_transaction.primary_hbx_id},family_hbx_id: #{old_transaction.family_hbx_id}"
            next
          end

          transaction.update_attributes!({ status: :transmitted, transmit_action: :no_transmit })
          transmission_path = ::H41::Transmissions::TransmissionPath.create(
            batch_reference: "2023-02-10T21:43:39Z",
            content_file_id: file_id,
            record_sequence_number: record_sequence_num,
            transaction: transaction,
            transmission: @old_original_transmission
          )
          csv << [
            old_transaction.primary_hbx_id,
            old_transaction.family_hbx_id,
            old_transaction.policy_hbx_id,
            posted_family.contract_holder_id,
            posted_family.family_hbx_id,
            policy.policy_hbx_id,
            policy.assistance_year,
            aptc_csr_tax_household.hbx_assigned_id,
            transmission_path.record_sequence_number_path
          ]
        end
      end

      @logger.info "Processed old_transaction with primary_hbx_id: #{old_transaction.primary_hbx_id}, family_hbx_id: #{old_transaction.family_hbx_id}"
      old_transaction.update_attributes!(is_migrated: true)
    rescue StandardError => e
      @logger.info "Error raised processing old_transaction with family_hbx_id: #{
        old_transaction.family_hbx_id}, error: #{e}, backtrace: #{e.backtrace}"
    end
  end
end
# rubocop:enable Metrics

start_time = DateTime.current
@logger = Logger.new("#{Rails.root}/handle_transmitted_transactions_#{Date.today.strftime('%Y_%m_%d')}.log")
@logger.info "Data Migration start_time: #{start_time}"
process_h41_transactions
end_time = DateTime.current
@logger.info "Data Migration end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_i}"
