# frozen_string_literal: true

TEST_APPLICATION_1 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "A",
        :middle_name => "GEORGE",
        :last_name => "PRESTEDIGITAGITATORS",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "B2vCRxjVT+wkKK4I1ESwNYECuf4LIslOlQ==\n",
        :ssn => "011789802"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1944, 11, 4),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "outstanding",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_2 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "JOHN",
        :middle_name => "JACOB",
        :last_name => "SMITH",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "3Anhgga7NaHpVchr9OTi7YUCvfkKL8FOkA==\n",
        :ssn => "415094007"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1946, 0o7, 13),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_3 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "RANDOLPH",
        :middle_name => "MICHAEL",
        :last_name => "RUDOLPH",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "pF1s19Wep5toMdRxHfAywoAGu/EHKcROlA==\n",
        :ssn => "153842503"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1991, 10, 22),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_4 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "VERONICA",
        :middle_name => nil,
        :last_name => "POWERS",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "iId0NR+8sS2x7LG02Ct6FIEFsP4HLsBOnw==\n",
        :ssn => "068745108"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1952, 0o6, 0o5),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_5 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "CHARLES",
        :middle_name => "F",
        :last_name => "DIXON",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "prqggGDxIboHLjps+Gg9HoEDv/8HKMFOlA==\n",
        :ssn => "007643003"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1947, 0o1, 16),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "outstanding",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_6 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "MAY",
        :middle_name => nil,
        :last_name => "FEATHER",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "GNTtdh8unj78rxyWvX7KxIMEuvgAKcJOkg==\n",
        :ssn => "272132305"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1949, 0o3, 0o2),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_7 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "SUSAN",
        :middle_name => "N",
        :last_name => "HEDGE",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "SBdBnh1cCA0uk7MdFtADuIECuPsLK8JOkA==\n",
        :ssn => "010280307"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1953, 12, 30),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_8 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "MARIAN",
        :middle_name => "LOVE",
        :last_name => "GIANTS",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "qRnaN721ulBW4q3k0+Z5ooEDu/4HI8VOlA==\n",
        :ssn => "003748403"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1995, 9, 24),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :foster_care => {
        :is_former_foster_care => false,
        :age_left_foster_care => nil,
        :foster_care_us_state => nil,
        :had_medicaid_during_foster_care => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_9 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "VINCENT",
        :middle_name => "VON",
        :last_name => "RUPERT",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "VT4oGl3fPrw9ZkERAGAerIIKvvwBI8FOkg==\n",
        :ssn => "396528005"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1951, 0o7, 18),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_10 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "BARBIE",
        :middle_name => "B",
        :last_name => "BROWN",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "a/XjCRqUzbz5aqCwpZFC0oECuP8FI8ZOlA==\n",
        :ssn => "010668703"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1950, 0o5, 14),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_11 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "CHRIS",
        :middle_name => nil,
        :last_name => "HOPE",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "ZocnE1smaxpU38VhhV02f4IFv/gLKcROkQ==\n",
        :ssn => "367182506"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1991, 0o7, 8),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_12 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "BESS",
        :middle_name => "MARGITE",
        :last_name => "EL TORO",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "vXWl1Exb3yi/fCU4/sXae4ECsP0DLclOnw==\n",
        :ssn => "018406808"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1994, 0o1, 25),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_13 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "HELEN",
        :middle_name => nil,
        :last_name => "DECOSTA",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "ChFxBJQIwg1oCW94ZV+rCYEEsP8FI8lOkg==\n",
        :ssn => "078668805"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1980, 0o2, 9),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_14 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "DOUGLAS",
        :middle_name => "SON",
        :last_name => "OFAGUN",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "qGhTvJo/RqXiCnU/JZWWBoIBufAHI8dOkQ==\n",
        :ssn => "321948606"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1950, 0o4, 17),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_15 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "MARY",
        :middle_name => "WHAT",
        :last_name => "CHADOIN",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "MDyqMdsgwrqsu9sUBvNjG4EDvP8DI8VOkA==\n",
        :ssn => "004608407"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1950, 0o5, 14),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_16 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "MONIQUE",
        :middle_name => "CURLY",
        :last_name => "LACET",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "ISdBV+tIAWixO/qyx/kOv4MBuPgFL8dOkg==\n",
        :ssn => "220164605"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1943, 0o4, 10),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze

TEST_APPLICATION_17 = {
  :family_reference => { :hbx_id => "10205" },
  :assistance_year => 2022,
  :aptc_effective_date => Date.new(2022, 10, 1),
  :years_to_renew => nil,
  :renewal_consent_through_year => 5,
  :is_ridp_verified => true,
  :is_renewal_authorized => true,
  :applicants => [
    {
      :name => {
        :first_name => "MATILDA",
        :middle_name => "B",
        :last_name => "BOTTOM",
        :name_sfx => nil,
        :name_pfx => nil
      },
      :identifying_information => {
        :has_ssn => "0",
        :encrypted_ssn => "m9Nx+5aDU5iUaNDXPTZjrIMKvf8LKcVOkA==\n",
        :ssn => "295682407"
      },
      :demographic => {
        :gender => "Male",
        :dob => Date.new(1950, 0o4, 17),
        :is_veteran_or_active_military => true
      },
      :attestation => {
        :is_incarcerated => false,
        :is_self_attested_disabled => false,
        :is_self_attested_blind => false,
        :is_self_attested_long_term_care => false
      },
      :is_primary_applicant => true,
      :citizenship_immigration_status_information => {
        :citizen_status => "us_citizen",
        :is_lawful_presence_self_attested => false,
        :is_resident_post_092296 => false
      },
      :is_applying_coverage => true,
      :is_consent_applicant => false,
      :vlp_document => nil,
      :family_member_reference => { :family_member_hbx_id => "98765432" },
      :person_hbx_id => "98765432",
      :is_required_to_file_taxes => false,
      :tax_filer_kind => "non_filer",
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
      :age_of_applicant => 33,
      :is_homeless => false,
      :benchmark_premium => {
        :health_only_lcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }],
        :health_only_slcsp_premiums => [{ :member_identifier => "98765432", :monthly_premium => 310.5 }]
      },
      :benefits => [],
      :non_esi_evidence => {
        :description => nil,
        :due_on => nil,
        :aasm_state => "attested",
        :external_service => nil,
        :key => :non_esi_mec,
        :title => "Non ESI MEC",
        :updated_by => nil
      }
    }
  ],
  :us_state => "DC",
  :hbx_id => "111222333",
  :oe_start_on => Date.new(2020, 10, 0o1),
  :notice_options => {
    :send_eligibility_notices => true,
    :send_open_enrollment_notices => false
  }
}.freeze


# (1..17).each do |index|
#   puts "processing #{index}"
#   result = Fdsh::Rrv::Medicare::Request::StoreApplicationRrvRequest.new.call("TEST_APPLICATION_#{index}".constantize)  
#   if result.success?
#     puts "stored successfully"
#   else
#     p "failed due to #{result.failures}"
#   end
# end


