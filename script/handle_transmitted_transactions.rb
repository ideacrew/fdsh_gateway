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

def get_transmitted_original_transmission(transmission_type, reporting_year)
  find_h41_transmission(transmission_type, reporting_year, :transmitted) || find_and_update_h41_open_transmission(transmission_type, reporting_year)
end

def find_h41_original_transmissions
  @old_original_transmission = get_transmitted_original_transmission(:original, 2022)
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

def policies_with_multi_thhs
  H41Transaction.all.non_migrated.exists({ :'aptc_csr_tax_households.1' => true }).pluck(:policy_hbx_id)
end

def find_matching_nodes_for_multi_thh_cases
  @find_matching_nodes_for_multi_thh_cases ||=
    @all_file_paths.inject({}) do |multiple_thh_xmls_info, file_path|
      content_file_xml_string = File.read(file_path)
      xml_doc = Nokogiri::XML(content_file_xml_string).xpath("//batchreq:Form1095ATransmissionUpstream").first
      xml_doc.xpath("//airty20a:Form1095AUpstreamDetail").each do |content_node|
        policy_id = content_node.xpath('./airty20a:Policy/airty20a:MarketPlacePolicyNum').text

        if policies_with_multi_thhs.include?(policy_id)
          if multiple_thh_xmls_info[policy_id].present?
            multiple_thh_xmls_info[policy_id][:xml_nodes] << content_node
          else
            multiple_thh_xmls_info[policy_id] = {
              content_file_id: File.basename(file_path).split('_')[2],
              xml_nodes: [content_node]
            }
          end
        end
      end
      multiple_thh_xmls_info
    end
end

def multi_thh_policies_hbx_ids_in_content_files
  @multi_thh_policies_hbx_ids_in_content_files ||= find_matching_nodes_for_multi_thh_cases.keys
end

# rubocop:disable Metrics
def process_h41_transactions(file_name, h41s_per_iteration, field_names, offset_count)
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names

    @h41_transactions.limit(h41s_per_iteration).offset(offset_count).no_timeout.each do |old_transaction|
      @logger.info "----- Processing H41Transaction FamilyHbxID: #{old_transaction.family_hbx_id}"
      policy = ::H41::InsurancePolicies::InsurancePolicy.where(policy_hbx_id: old_transaction.policy_hbx_id).first
      if policy.blank?
        @logger.info "Could not find InsurancePolicy with policy_hbx_id: #{
          old_transaction.policy_hbx_id}, primary_hbx_id: #{old_transaction.primary_hbx_id}, family_hbx_id: #{old_transaction.family_hbx_id}"
        next
      end

      posted_family = policy.posted_family
      policy.aptc_csr_tax_households.each do |aptc_csr_tax_household|
        record_sequence_num, file_id = fetch_transmission_path_attrs(old_transaction, aptc_csr_tax_household, policy.policy_hbx_id)
        if record_sequence_num.blank? || file_id.blank?
          @logger.info "Could not find record_sequence_num & file_id for old_transaction policy_hbx_id: #{
            old_transaction.policy_hbx_id}, primary_hbx_id: #{old_transaction.primary_hbx_id},family_hbx_id: #{old_transaction.family_hbx_id}"
          next
        end

        aptc_csr_tax_household.transactions.each do |transaction|
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
rescue StandardError => e
  @logger.info "Error raised message: #{e}, backtrace: #{e.backtrace}"
end
# rubocop:enable Metrics

def fetch_transmission_path_attrs_single_thh(policy_hbx_id)
  expected_file_path = find_content_file_path(policy_hbx_id)
  return [nil, nil] if expected_file_path.nil?

  record_sequence_element_start = '<airty20a:RecordSequenceNum>'
  record_sequence_element_end = '</airty20a:RecordSequenceNum>'
  record_sequence_num_extention = @content_file_xml_string[/#{record_sequence_element_start}#{policy_hbx_id}(.*?)#{record_sequence_element_end}/m, 1]
  [policy_hbx_id + record_sequence_num_extention, File.basename(expected_file_path).split('_')[2]]
end

def find_content_file_path(policy_hbx_id)
  market_place_policy_num_start_ele = '<airty20a:MarketPlacePolicyNum>'
  market_place_policy_num_end_ele = '</airty20a:MarketPlacePolicyNum>'
  market_place_policy_snippet = "#{market_place_policy_num_start_ele}#{policy_hbx_id}#{market_place_policy_num_end_ele}"

  @all_file_paths.detect do |file_path|
    @content_file_xml_string = File.read(file_path)
    @content_file_xml_string.match?(market_place_policy_snippet)
  end
end

def fetch_transmission_path_attrs(old_transaction, aptc_csr_tax_household, policy_hbx_id)
  if old_transaction.aptc_csr_tax_households.count == 1
    fetch_transmission_path_attrs_single_thh(policy_hbx_id)
  else
    return [nil, nil] if multi_thh_policies_hbx_ids_in_content_files.exclude?(policy_hbx_id)

    content_file_info_hash_for_policy = find_matching_nodes_for_multi_thh_cases[policy_hbx_id]
    file_id = content_file_info_hash_for_policy[:content_file_id]
    found_node = content_file_info_hash_for_policy[:xml_nodes].detect do |node|
      @record_sequence_number = node.xpath('./airty20a:RecordSequenceNum').text
      policy_id = node.xpath('./airty20a:Policy/airty20a:MarketPlacePolicyNum').text

      policy_hbx_id == policy_id && matching_thh_info?(node, aptc_csr_tax_household)
    end
    return [nil, nil] if found_node.blank?

    [@record_sequence_number, file_id]
  end
end

def matching_thh_info?(node, aptc_csr_tax_household)
  content_recipient_ssn = node.xpath('./airty20a:Recipient/irs:SSN').text
  thh_node = Nokogiri::XML(aptc_csr_tax_household.transaction_xml).xpath("//airty20a:Form1095AUpstreamDetail").first
  recipient_ssn = thh_node.xpath('./airty20a:Recipient/irs:SSN').text
  return content_recipient_ssn == recipient_ssn if content_recipient_ssn.present?

  content_recipient_dob = node.xpath('./airty20a:Recipient/airty20a:BirthDt').text
  content_recipient_fn = node.xpath('./airty20a:Recipient/airty20a:OtherCompletePersonName/airty20a:PersonFirstNm').text
  content_recipient_ln = node.xpath('./airty20a:Recipient/airty20a:OtherCompletePersonName/airty20a:PersonLastNm').text

  recipient_dob = thh_node.xpath('./airty20a:Recipient/airty20a:BirthDt').text
  recipient_fn = thh_node.xpath('./airty20a:Recipient/airty20a:OtherCompletePersonName/airty20a:PersonFirstNm').text
  recipient_ln = thh_node.xpath('./airty20a:Recipient/airty20a:OtherCompletePersonName/airty20a:PersonLastNm').text

  content_recipient_dob == recipient_dob && content_recipient_fn == recipient_fn && content_recipient_ln == recipient_ln
end

start_time = DateTime.current
@logger = Logger.new("#{Rails.root}/handle_transmitted_transactions_#{Date.today.strftime('%Y_%m_%d')}.log")
@logger.info "Data Migration start_time: #{start_time}"
@all_file_paths = Dir["#{Rails.root}/SBE00ME.DSH.EOYIN.D230210.T214339000.P.IN.SUBMIT.20230210/EOY_Request_*.xml"]
find_matching_nodes_for_multi_thh_cases
find_h41_original_transmissions
@h41_transactions = H41Transaction.all.non_migrated
total_count = @h41_transactions.count
h41s_per_iteration = 5_000.0
number_of_iterations = (total_count / h41s_per_iteration).ceil
counter = 0

field_names = %w[
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

while counter < number_of_iterations
  file_name = "#{Rails.root}/handle_transmitted_transactions_#{counter + 1}_#{Date.today.strftime('%Y_%m_%d')}.csv"
  @logger.info "Total number of non_migrated H41Transactions: #{total_count}"
  offset_count = h41s_per_iteration * counter
  process_h41_transactions(file_name, h41s_per_iteration, field_names, offset_count)
  @logger.info "---------- Processed #{counter.next.ordinalize} #{h41s_per_iteration} h41 transactions"
  counter += 1
end

end_time = DateTime.current
@logger.info "Data Migration end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_i}"
