# frozen_string_literal: true

# bundle exec rails runner script/irs_1095a_csv_report.rb "2022", "open" (pass in year and status)

require "csv"
require "money"

transmission_status = [:open, :pending, :transmitted]
@tax_year = ARGV[0].to_i
@status = transmission_status.include?(ARGV[1]&.to_sym) ? ARGV[1]&.to_sym : "all"

@fields = %w[PLAN_YEAR TRANSACTION_TYPE TRANSACTION_DATETIME TRANSACTION_STATUS TRANSMISSION_STATUS FAMILY_HBX_ID
             CONTRACT_HOLDER_ID PRIMARY_PERSON_ID MARKETPLACE_ID POLICY_ID ISSUER_NAME RECIPIENT_NAME RECIPIENT_SSN
             RECIPIENT_DOB SPOUSE_NAME SPOUSE_SSN
             SPOUSE_DOB POLICY_START POLICY_END STREET_ADDRESS CITY
             STATE ZIPCODE COVERED_NAME_1 COVERED_SSN_1 COVERED_DOB_1 COVERED_START_1 COVERED_END_1 COVERED_NAME_2
             COVERED_SSN_2 COVERED_DOB_2 COVERED_START_2 COVERED_END_2 COVERED_NAME_3 COVERED_SSN_3 COVERED_DOB_3
             COVERED_START_3 COVERED_END_3 COVERED_NAME_4 COVERED_SSN_4 COVERED_DOB_4 COVERED_START_4 COVERED_END_4
             COVERED_NAME_5 COVERED_SSN_5 COVERED_DOB_5 COVERED_START_5 COVERED_END_5 COVERED_NAME_6 COVERED_SSN_6
             COVERED_DOB_6 COVERED_START_6 COVERED_END_6 COVERED_NAME_7 COVERED_SSN_7 COVERED_DOB_7 COVERED_START_7
             COVERED_END_7 COVERED_NAME_8 COVERED_SSN_8 COVERED_DOB_8 COVERED_START_8 COVERED_END_8 COVERED_NAME_9
             COVERED_SSN_9 COVERED_DOB_9 COVERED_START_9 COVERED_END_9 COVERED_NAME_10 COVERED_SSN_10 COVERED_DOB_10
             COVERED_START_10 COVERED_END_10 PREMIUM_1 SLCSP_1 APTC_1 PREMIUM_2 SLCSP_2 APTC_2
             PREMIUM_3 SLCSP_3 APTC_3 PREMIUM_4 SLCSP_4 APTC_4 PREMIUM_5 SLCSP_5 APTC_5 PREMIUM_6
             SLCSP_6 APTC_6 PREMIUM_7 SLCSP_7 APTC_7 PREMIUM_8 SLCSP_8 APTC_8 PREMIUM_9 SLCSP_9 APTC_9
             PREMIUM_10 SLCSP_10 APTC_10 PREMIUM_11 SLCSP_11 APTC_11 PREMIUM_12 SLCSP_12 APTC_12 PREMIUM_13 SLCSP_13
             APTC_13]

def address
  if @recipient.person
    @recipient.person.addresses.detect { |address| address.kind == 'mailing' } || @recipient.person.addresses.first
  else
    @recipient.addresses.detect { |address| address.kind == 'mailing' } || @recipient.addresses.first
  end
end

def decrypt_ssn(encrypted_ssn)
  return "" if encrypted_ssn.blank?

  AcaEntities::Operations::Encryption::Decrypt.new.call({ value: encrypted_ssn }).value!
end

def recipient(aptc_csr_tax_household, contract_holder, family)
  tax_filers = aptc_csr_tax_household.covered_individuals.select do |covered_individual|
    covered_individual.filer_status == 'tax_filer'
  end

  tax_filer =
    if tax_filers.count == 1
      tax_filers.first
    elsif tax_filers.count > 1
      tax_filers.detect { |tx_filer| tx_filer.relation_with_primary == 'self' }
    end

  return tax_filer if tax_filer.present?

  family.family_members.detect do |family_member|
    family_member.person.hbx_id == contract_holder.hbx_id
  end
end

def fetch_transmission_type
  case @transmission.class.name
  when "H41::Transmissions::Outbound::OriginalTransmission"
    "original"
  when "H41::Transmissions::Outbound::CorrectedTransmission"
    "corrected"
  when "H41::Transmissions::Outbound::VoidTransmission"
    "void"
  else
    ""
  end
end

def fetch_covered_members(covered_individuals)
  (0..9).collect do |index|
    individual = covered_individuals[index]
    if individual.present?
      person = individual.person
      ["#{person.person_name.first_name} #{person.person_name.last_name}",
       decrypt_ssn(person.person_demographics.encrypted_ssn), person.person_demographics.dob,
       individual.coverage_start_on, individual.coverage_end_on]
    else
      ["", "", "", "", ""]
    end
  end
end

def fetch_premium_values(months_of_year)
  (1..12).collect do |index|
    coverage_month = Date::MONTHNAMES[index]
    month_premiums = months_of_year.detect { |coverage| coverage.present? && coverage.month == coverage_month }
    if month_premiums.present?
      coverage_information = month_premiums.coverage_information
      [format("%.2f", Money.new(coverage_information.total_premium.cents).to_f),
       format("%.2f", Money.new(coverage_information.slcsp_benchmark_premium.cents).to_f),
       format("%.2f", Money.new(coverage_information.tax_credit.cents).to_f)]
    else
      ["", "", ""]
    end
  end
end

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity
def process_aptc_csr_tax_households(transactions, file_name, offset_count)
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << @fields
    transactions.offset(offset_count).limit(20_000).no_timeout.each do |transaction|
      subject = transaction.transactable
      insurance_policy = subject.insurance_policy
      posted_family = insurance_policy.posted_family
      family_cv = posted_family.family_cv

      if family_cv.blank?
        @logger.info "No family cv attached for subject #{subject.hbx_assigned_id}"
        next
      end

      family_hash = JSON.parse(family_cv, symbolize_names: true)
      contract = AcaEntities::Contracts::Families::FamilyContract.new.call(family_hash)
      family = AcaEntities::Families::Family.new(contract.to_h)

      agreements = family.households.first.insurance_agreements
      contract_holder = agreements.first.contract_holder
      policies = agreements.flat_map(&:insurance_policies)
      valid_policy = policies.detect do |policy|
        policy.policy_id == insurance_policy.policy_hbx_id
      end
      insurance_provider = valid_policy.insurance_provider
      valid_tax_household = valid_policy.aptc_csr_tax_households.detect do |tax_household|
        tax_household.hbx_assigned_id == subject.hbx_assigned_id
      end
      next if valid_tax_household.blank?

      @recipient = recipient(valid_tax_household, contract_holder, family)
      covered_individuals = valid_tax_household.covered_individuals
      @spouse = valid_tax_household.covered_individuals.detect do |covered_individual|
        covered_individual.relation_with_primary == 'spouse'
      end

      @has_aptc = valid_tax_household.months_of_year.any? do |month|
        month.coverage_information && month.coverage_information.tax_credit.cents.positive?
      end

      @calender_year = @tax_year.to_i
      months_of_year = valid_tax_household.months_of_year
      annual_premiums = valid_tax_household.annual_premiums

      covered_members_result = fetch_covered_members(covered_individuals)
      premium_values = fetch_premium_values(months_of_year)

      csv << ([@tax_year,
               @transmission_type,
               transaction.created_at,
               transaction.status,
               @transmission.status,
               posted_family.family_hbx_id,
               posted_family.contract_holder_id,
               @recipient.person.hbx_id,
               "ME",
               valid_policy.policy_id,
               insurance_provider.title,
               "#{@recipient.person.person_name.first_name} #{@recipient.person.person_name.last_name}",
               decrypt_ssn(@recipient&.person&.person_demographics&.encrypted_ssn),
               @recipient&.person&.person_demographics&.dob,
               @has_aptc ? "#{@spouse&.person&.person_name&.first_name} #{@spouse&.person&.person_name&.last_name}" : "",
               @has_aptc ? decrypt_ssn(@spouse&.person&.person_demographics&.encrypted_ssn) : "",
               @has_aptc ? @spouse&.person&.person_demographics&.dob : "",
               valid_policy.start_on,
               valid_policy.end_on,
               address&.address_1,
               address&.city,
               address&.state,
               address&.zip] + covered_members_result[0] +
        covered_members_result[1] + covered_members_result[2] +
        covered_members_result[3] + covered_members_result[4] + covered_members_result[5] +
        covered_members_result[6] + covered_members_result[7] + covered_members_result[8] +
        covered_members_result[9] +
        premium_values[0] + premium_values[1] + premium_values[2] + premium_values[3] + premium_values[4] +
        premium_values[5] + premium_values[6] + premium_values[7] + premium_values[8] + premium_values[9] +
        premium_values[10] + premium_values[11] +
        [format("%.2f", Money.new(annual_premiums.total_premium.cents).to_f),
         format("%.2f", Money.new(annual_premiums.slcsp_benchmark_premium.cents).to_f),
         format("%.2f", Money.new(annual_premiums.tax_credit.cents).to_f)])
    rescue StandardError => e
      @logger.info "Unable to populate data for subject #{transaction.transactable.hbx_assigned_id} due to #{e}"
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/PerceivedComplexity

original_transmission = H41::Transmissions::Outbound::OriginalTransmission.by_year(@tax_year)
corrected_transmission = H41::Transmissions::Outbound::CorrectedTransmission.by_year(@tax_year)
void_transmission = H41::Transmissions::Outbound::VoidTransmission.by_year(@tax_year)

original_transmissions = @status == "all" ? original_transmission : original_transmission.by_status(@status).to_a
corrected_transmissions = @status == "all" ? corrected_transmission : corrected_transmission.by_status(@status).to_a
void_transmissions = @status == "all" ? void_transmission : void_transmission.by_status(@status).to_a

[original_transmissions, corrected_transmissions, void_transmissions].flatten.each do |transmission|
  @transmission = transmission
  @transmission_type = fetch_transmission_type
  transactions = transmission.transactions
  transactions_count = transactions.count
  transactions_per_iteration = [transactions_count, 20_000.0].min
  @logger = Logger.new("#{Rails.root}/log/1095A-FormData_errors_#{@transmission._id}_#{Date.today.strftime('%Y_%m_%d_%H_%M')}.log")

  if transactions_count == 0
    @logger.info "No transactions for transmission id #{@transmission._id}"
    next
  end

  number_of_iterations = (transactions_count / transactions_per_iteration).ceil
  counter = 0

  while counter < number_of_iterations
    file_name = "#{Rails.root}/1095A-FormData_#{@transmission.class.to_s.demodulize}_#{
      @transmission.status}_#{counter}_#{@transmission.created_at.strftime('%Y_%m_%d_%H_%M')}.csv"
    offset_count = transactions_per_iteration * counter
    process_aptc_csr_tax_households(transactions, file_name, offset_count)
    counter += 1
  end
end
