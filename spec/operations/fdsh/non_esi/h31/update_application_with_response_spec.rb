# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe Fdsh::NonEsi::H31::UpdateApplicationWithResponse do

  let(:application_params) do
    {
      :family_reference => { :hbx_id => "10205" },
      :assistance_year => 2021,
      :aptc_effective_date => Date.new(2021, 10, 0o1),
      :years_to_renew => nil,
      :renewal_consent_through_year => 5,
      :is_ridp_verified => true,
      :is_renewal_authorized => true,
      :applicants => [
        {
          :name => {
            :first_name => "CLARA",
            :middle_name => 'K',
            :last_name => "STEPHENS",
            :name_sfx => nil,
            :name_pfx => nil
          },
          :identifying_information => {
            :has_ssn => "0",
            :encrypted_ssn => "yobheUbYUK2Abfc6lrq37YQCsPgBL8lLkw==\n",
            :ssn => "518124854"
          },
          :demographic => {
            :gender => "Male",
            :dob => Date.new(1988, 11, 11),
            :ethnicity => ["", "", "", "", "", "", ""],
            :race => nil, :is_veteran_or_active_military => false,
            :is_vets_spouse_or_child => false
          },
          :attestation => {
            :is_incarcerated => false,
            :is_self_attested_disabled => false,
            :is_self_attested_blind => false,
            :is_self_attested_long_term_care => false
          },
          :is_primary_applicant => true,
          :native_american_information => {
            :indian_tribe_member => false,
            :tribal_id => nil
          },
          :citizenship_immigration_status_information => {
            :citizen_status => "us_citizen",
            :is_lawful_presence_self_attested => false,
            :is_resident_post_092296 => false
          },
          :is_consumer_role => true,
          :is_resident_role => false,
          :is_applying_coverage => true,
          :is_consent_applicant => false,
          :vlp_document => nil,
          :family_member_reference => {
            :family_member_hbx_id => "1629165429385938",
            :first_name => "esi",
            :last_name => "evidence",
            :person_hbx_id => "1629165429385938",
            :is_primary_family_member => true
          },
          :person_hbx_id => "1629165429385938",
          :is_required_to_file_taxes => false,
          :is_filing_as_head_of_household => false,
          :is_joint_tax_filing => false,
          :is_claimed_as_tax_dependent => false,
          :claimed_as_tax_dependent_by => nil,
          :tax_filer_kind => "non_filer",
          :student => {
            :is_student => false,
            :student_kind => "",
            :student_school_kind => "",
            :student_status_end_on => ""
          },
          :is_refugee => false,
          :is_trafficking_victim => false,
          :foster_care => {
            :is_former_foster_care => false,
            :age_left_foster_care => nil, :foster_care_us_state => "",
            :had_medicaid_during_foster_care => false
          },
          :pregnancy_information => {
            :is_pregnant => false,
            :is_enrolled_on_medicaid => false,
            :is_post_partum_period => false,
            :expected_children_count => nil,
            :pregnancy_due_on => nil,
            :pregnancy_end_on => nil
          },
          :is_subject_to_five_year_bar => false,
          :is_five_year_bar_met => false,
          :is_forty_quarters => false,
          :is_ssn_applied => false,
          :non_ssn_apply_reason => nil,
          :moved_on_or_after_welfare_reformed_law => false,
          :is_currently_enrolled_in_health_plan => false,
          :has_daily_living_help => false,
          :need_help_paying_bills => false,
          :has_job_income => false,
          :has_self_employment_income => false,
          :has_unemployment_income => false,
          :has_other_income => false,
          :has_deductions => false,
          :has_enrolled_health_coverage => false,
          :has_eligible_health_coverage => false,
          :job_coverage_ended_in_past_3_months => false,
          :job_coverage_end_date => nil,
          :medicaid_and_chip => {
            :not_eligible_in_last_90_days => false,
            :denied_on => nil,
            :ended_as_change_in_eligibility => false,
            :hh_income_or_size_changed => false,
            :medicaid_or_chip_coverage_end_date => nil,
            :ineligible_due_to_immigration_in_last_5_years => false,
            :immigration_status_changed_since_ineligibility => false
          },
          :other_health_service => {
            :has_received => false,
            :is_eligible => false
          },
          :addresses => [
            {
              :kind => "home",
              :address_1 => "dc",
              :address_2 => "",
              :address_3 => "",
              :city => "dc",
              :county => "",
              :state => "DC",
              :zip => "22302",
              :country_name => ""
            }
          ],
          :emails => [],
          :phones => [],
          :incomes => [],
          :benefits => [
            {
              :name => nil,
              :kind => "medicare",
              :status => "is_enrolled",
              :is_employer_sponsored => false,
              :employer => nil,
              :esi_covered => nil,
              :is_esi_waiting_period => false,
              :is_esi_mec_met => false,
              :employee_cost => 0,
              :employee_cost_frequency => nil,
              :start_on => Date.today,
              :end_on => nil,
              :submitted_at => DateTime.now,
              :hra_kind => nil
            },
            # {
            #   :name=>nil,
            #   :kind=>"veterans_administration_health_benefits",
            #   :status=>"is_enrolled",
            #   :is_employer_sponsored=>false,
            #   :employer=>nil,
            #   :esi_covered=>nil,
            #   :is_esi_waiting_period=>false,
            #   :is_esi_mec_met=>false,
            #   :employee_cost=> 0,
            #   :employee_cost_frequency=>nil,
            #   :start_on=>Date.today,
            #   :end_on=>nil,
            #   :submitted_at=>DateTime.now,
            #   :hra_kind=>nil
            # },
            {
              :name => nil,
              :kind => "tricare",
              :status => "is_eligible",
              :is_employer_sponsored => false,
              :employer => nil,
              :esi_covered => nil,
              :is_esi_waiting_period => false,
              :is_esi_mec_met => false,
              :employee_cost => 0,
              :employee_cost_frequency => nil,
              :start_on => Date.today,
              :end_on => nil,
              :submitted_at => DateTime.now,
              :hra_kind => nil
            },
            {
              :name => nil,
              :kind => "acf_refugee_medical_assistance",
              :status => "is_eligible",
              :is_employer_sponsored => false,
              :employer => nil,
              :esi_covered => nil,
              :is_esi_waiting_period => false,
              :is_esi_mec_met => false,
              :employee_cost => 0,
              :employee_cost_frequency => nil,
              :start_on => Date.today,
              :end_on => nil,
              :submitted_at => DateTime.now,
              :hra_kind => nil
            }
          ],
          :deductions => [],
          :is_medicare_eligible => false,
          :is_self_attested_long_term_care => false,
          :has_insurance => false,
          :has_state_health_benefit => false,
          :had_prior_insurance => false,
          :prior_insurance_end_date => nil,
          :age_of_applicant => 33,
          :hours_worked_per_week => 0,
          :is_temporarily_out_of_state => false,
          :is_claimed_as_dependent_by_non_applicant => false,
          :benchmark_premium => {
            :health_only_lcsp_premiums => [
              {
                :member_identifier => "1629165429385938",
                :monthly_premium => 310.5
              }
            ],
            :health_only_slcsp_premiums => [
              {
                :member_identifier => "1629165429385938",
                :monthly_premium => 310.5
              }
            ]
          },
          :is_homeless => false,
          :mitc_income => {
            :amount => 0,
            :taxable_interest => 0,
            :tax_exempt_interest => 0,
            :taxable_refunds => 0,
            :alimony => 0,
            :capital_gain_or_loss => 0,
            :pensions_and_annuities_taxable_amount => 0,
            :farm_income_or_loss => 0,
            :unemployment_compensation => 0,
            :other_income => 0,
            :magi_deductions => 0,
            :adjusted_gross_income => 0,
            :deductible_part_of_self_employment_tax => 0,
            :ira_deduction => 0,
            :student_loan_interest_deduction => 0,
            :tution_and_fees => 0,
            :other_magi_eligible_income => 0
          },
          :non_esi_evidence => {
            :description => nil,
            :due_on => nil,
            :aasm_state => "attested",
            :external_service => nil,
            :key => :non_esi_mec,
            :title => "Non ESI MEC",
            :updated_by => nil
          },
          :mitc_relationships => [],
          :mitc_is_required_to_file_taxes => false
        }
      ],
      :relationships => [],
      :tax_households => [
        {
          :hbx_id => "10071",
          :max_aptc => 0,
          :is_insurance_assistance_eligible => nil,
          :annual_tax_household_income => 0,
          :tax_household_members => [
            {
              :applicant_reference => {
                :first_name => "CLARA",
                :last_name => "STEPHENS",
                :dob => Date.new(1988, 11, 11),
                :person_hbx_id => "1629165429385938",
                :encrypted_ssn => "yobheUbYUK2Abfc6lrq37YQCsPgBL8lLkw==\n"
              },
              :product_eligibility_determination => {
                :is_ia_eligible => false,
                :is_medicaid_chip_eligible => false,
                :is_totally_ineligible => false,
                :is_magi_medicaid => false,
                :is_non_magi_medicaid_eligible => false,
                :is_without_assistance => false,
                :magi_medicaid_monthly_household_income => 0,
                :medicaid_household_size => nil,
                :magi_medicaid_monthly_income_limit => 0,
                :magi_as_percentage_of_fpl => 0.0,
                :magi_medicaid_category => nil
              }
            }
          ]
        }
      ],
      :us_state => "DC",
      :hbx_id => "43140d1664a1457bae5474d204f51b12",
      :oe_start_on => Date.new(2020, 10, 0o1),
      :notice_options => {
        :send_eligibility_notices => true,
        :send_open_enrollment_notices => false
      },
      :mitc_households => [
        { :household_id => "1",
          :people => [
            {
              :person_id => "1629165429385938"
            }
          ] }
      ],
      :mitc_tax_returns => [
        {
          :filers => [
            { :person_id => "1629165429385938" }
          ],
          :dependents => []
        }
      ]
    }
  end

  let(:application) { AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(application_params).value! }

  context "in case of failure response" do

    let(:mini_response_params) do
      {
        :ResponseMetadata => { :ResponseCode => "HE000001", :ResponseDescriptionText => "Applicant Not Found" }
      }
    end

    let(:non_esi_response) {AcaEntities::Fdsh::NonEsi::H31::VerifyNonESIMECResponse.new(mini_response_params)}

    before do
      @result1 = described_class.new.call(application, non_esi_response, application.hbx_id)
    end

    it "is successful" do
      expect(@result1.success?).to be_truthy
    end

    it "result to be an Application object" do
      expect(@result1.value!).to be_a AcaEntities::MagiMedicaid::Application
    end

    it "evidence should be in attested state" do
      applicant = @result1.value!.applicants.first
      expect(applicant.non_esi_evidence.aasm_state).to eq 'attested'
    end
  end

  context "in case of failure response" do

    let(:max_response_params) do
      {
        :IndividualResponseSet => {
          :IndividualResponses => [
            {
              :Applicant => {
                :PersonSSNIdentification => "518124854",
                :PersonName => {
                  :PersonGivenName => "CLARA",
                  :PersonMiddleName => "K",
                  :PersonSurName => "STEPHENS",
                  :PersonNameSuffixText => nil
                },
                :PersonBirthDate => Date.new(1988, 11, 11),
                :PersonSexCode => "M"
              },
              :PartialResponseIndicator => false,
              :OtherCoverages => [
                {
                  :OrganizationCode => "BHPC",
                  :ResponseMetadata => { :ResponseCode => "HE007001", :ResponseDescriptionText => "Service Not Provided" },
                  :MECCoverage => { :LocationStateUSPostalServiceCode => "AL", :MECVerificationCode => "N", :Insurances => [] }
                },
                {
                  :OrganizationCode => "PECO",
                  :ResponseMetadata => { :ResponseCode => "HE000001", :ResponseDescriptionText => "Applicant Not Found" },
                  :MECCoverage => { :LocationStateUSPostalServiceCode => nil, :MECVerificationCode => "N", :Insurances => [] }
                },
                {
                  :OrganizationCode => "TRIC",
                  :ResponseMetadata => { :ResponseCode => "HE000001", :ResponseDescriptionText => "Applicant Not Found" },
                  :MECCoverage => { :LocationStateUSPostalServiceCode => nil, :MECVerificationCode => "N", :Insurances => [] }
                },
                {
                  :OrganizationCode => "MEDI",
                  :ResponseMetadata => { :ResponseCode => "HE040008", :ResponseDescriptionText => "SSN does not match" },
                  :MECCoverage => { :LocationStateUSPostalServiceCode => nil, :MECVerificationCode => "N", :Insurances => [] }
                },
                {
                  :OrganizationCode => "VHPC",
                  :ResponseMetadata => { :ResponseCode => "HE000000", :ResponseDescriptionText => "Success" },
                  :MECCoverage => { :LocationStateUSPostalServiceCode => 'AL', :MECVerificationCode => "Y", :Insurances => [] }
                },
                {
                  :OrganizationCode => "CHIP",
                  :ResponseMetadata => { :ResponseCode => "HE000001", :ResponseDescriptionText => "Applicant Not Found" },
                  :MECCoverage => { :LocationStateUSPostalServiceCode => "AL", :MECVerificationCode => "N", :Insurances => [] }
                },
                {
                  :OrganizationCode => "MEDC",
                  :ResponseMetadata => { :ResponseCode => "HE000001", :ResponseDescriptionText => "Applicant Not Found" },
                  :MECCoverage => { :LocationStateUSPostalServiceCode => "AL", :MECVerificationCode => "N", :Insurances => [] }
                }
              ]
            }
          ]
        }
      }
    end

    let(:non_esi_response) {AcaEntities::Fdsh::NonEsi::H31::VerifyNonESIMECResponse.new(max_response_params)}

    before do
      @result2 = described_class.new.call(application, non_esi_response, application.hbx_id)
    end

    it "is successful" do
      expect(@result2.success?).to be_truthy
    end

    it "result to be an Application object" do
      expect(@result2.value!).to be_a AcaEntities::MagiMedicaid::Application
    end

    it "evidence should be in outstanding state" do
      applicant = @result2.value!.applicants.first
      expect(applicant.non_esi_evidence.aasm_state).to eq 'outstanding'
    end
  end
end