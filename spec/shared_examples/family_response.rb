# frozen_string_literal: true

RSpec.shared_context 'family response from enroll', :shared_context => :metadata do
  let(:verification_types) do
    [
      {
        :type_name => "American Indian Status",
        :validation_status => "outstanding",
        :due_date => Date.today + 45.days
      }
    ]
  end

  let(:current_date) { Date.today }

  let(:family_hash) do
    {
      :documents_needed => true,
      :hbx_id => '43456',
      :family_members => [family_member_2, family_member_1],
      :households => households
    }
  end

  let(:consumer_role_2) do
    {
      is_applying_coverage: true,
      contact_method: contact_method,
      five_year_bar: false,
      requested_coverage_start_date: Date.today,
      aasm_state: 'fully_verified',
      is_applicant: true,
      is_state_resident: true,
      identity_validation: 'na',
      identity_update_reason: 'na',
      application_validation: 'na',
      application_update_reason: 'na',
      identity_rejected: false,
      application_rejected: false,
      lawful_presence_determination: {}
    }
  end

  let(:consumer_role_1) do
    {
      is_applying_coverage: true,
      contact_method: contact_method,
      five_year_bar: false,
      requested_coverage_start_date: Date.today,
      aasm_state: 'fully_verified',
      is_applicant: true,
      is_state_resident: true,
      identity_validation: 'na',
      identity_update_reason: 'na',
      application_validation: 'na',
      application_update_reason: 'na',
      identity_rejected: false,
      application_rejected: false,
      lawful_presence_determination: {}
    }
  end

  let(:contact_method) { 'Paper, Electronic and Text Message communications' }

  let(:person_name_1) do
    { :first_name => "John", :last_name => "Smith" }
  end

  let(:family_member_1) do
    {
      :is_primary_applicant => true,
      :person => {
        :hbx_id => "1000595",
        :person_name => person_name_1,
        :person_demographics => {
          :ssn => "784796992",
          :gender => "male",
          :dob => Date.new(1972, 4, 4),
          :is_incarcerated => false
        },
        :consumer_role => consumer_role_1,
        :person_health => { :is_tobacco_user => "unknown" },
        :is_active => true,
        :is_disabled => false,
        :addresses => [{ :kind => 'mailing', :address_1 => 'H st', :state => "ME", :city => 'Augusta', :zip => '67662' }],
        :verification_types => verification_types
      }
    }
  end

  let(:family_member_2) do
    {
      :is_primary_applicant => false,
      :person => {
        :hbx_id => "476",
        :person_name => { :first_name => "John", :last_name => "Smith2" },
        :person_demographics => {
          :ssn => "784796993",
          :gender => "male",
          :dob => Date.new(1978, 4, 4),
          :is_incarcerated => false
        },
        :consumer_role => consumer_role_2,
        :person_health => { :is_tobacco_user => "unknown" },
        :is_active => true,
        :is_disabled => false,
        :addresses => [{ :kind => 'mailing', :address_1 => 'H st', :state => "ME", :city => 'Augusta', :zip => '67662' }],
        :verification_types => verification_types
      }
    }
  end

  let(:households) do
    [
      {
        :start_date => Date.today,
        :is_active => true,
        :irs_group_reference => {},
        :coverage_households => [
          {
            :is_immediate_family => true,
            :coverage_household_members => [{ :is_subscriber => true }]
          },
          {
            :is_immediate_family => false,
            :coverage_household_members => []
          }
        ],
        :hbx_enrollments => hbx_enrollments,
        :insurance_agreements => insurance_agreements
      }
    ]
  end

  let(:hbx_enrollments) do
    [
      {
        :is_receiving_assistance => true,
        :effective_on => Date.today,
        :aasm_state => "coverage_selected",
        :applied_aptc_amount => { cents: BigDecimal(44_500), currency_iso: 'USD' },
        :market_place_kind => "individual",
        :total_premium => 445.09,
        :enrollment_period_kind => "open_enrollment",
        :product_kind => "health",
        :hbx_enrollment_members => hbx_enrollment_members,
        :product_reference => product_reference,
        :issuer_profile_reference => issuer_profile_reference,
        :consumer_role_reference => consumer_role_preference
      }
    ]
  end

  let(:months_of_year) do
    [
      {
        month: "January",
        coverage_information: {
          tax_credit: {
            cents: 500.0,
            currency_iso: "USD"
          },
          total_premium: {
            cents: 50_000,
            currency_iso: "USD"
          },
          slcsp_benchmark_premium: {
            cents: 50_000,
            currency_iso: "USD"
          }
        }
      },
      {
        month: "February",
        coverage_information: {
          tax_credit: {
            cents: 500.0,
            currency_iso: "USD"
          },
          total_premium: {
            cents: 50_000,
            currency_iso: "USD"
          },
          slcsp_benchmark_premium: {
            cents: 50_000,
            currency_iso: "USD"
          }
        }
      }
    ]
  end

  let(:annual_premiums) do
    {
      tax_credit: {
        cents: 60_000,
        currency_iso: "USD"
      },
      total_premium: {
        cents: 600_000,
        currency_iso: "USD"
      },
      slcsp_benchmark_premium: {
        cents: 600_000,
        currency_iso: "USD"
      }
    }
  end

  let(:addresses) do
    [
      {
        kind: "home",
        address_1: "S Street NW",
        address_2: "",
        address_3: "",
        city: "Awesome city",
        county_name: "Awesome county",
        state: "DC",
        zip: "20002"
      }
    ]
  end

  let(:insurance_policy_enrollments) do
    [
      {
        start_on: current_date.beginning_of_year,
        subscriber: {
          member: {
            hbx_id: "1000595",
            member_id: "1000595",
            person_name: person_name_1
          },
          dob: "",
          gender: "male",
          addresses: [
            {
              kind: "home",
              address_1: "S Street NW",
              address_2: "",
              address_3: "",
              city: "Awesome city",
              county_name: "Awesome county",
              state: "DC",
              zip: "20002"
            }
          ],
          emails: [
            {
              kind: "home",
              address: "test@gmail.com"
            }
          ]
        },
        dependents: [],
        total_premium_amount: {
          cents: 50_000,
          currency_iso: "USD"
        },
        tax_households: [
          {
            hbx_id: "828762",
            tax_household_members: [
              {
                family_member_reference: {
                  family_member_hbx_id: "1000595",
                  relation_with_primary: "self"
                },
                tax_filer_status: "tax_filer",
                is_subscriber: true
              }
            ]
          }
        ],
        total_premium_adjustment_amount: {
          cents: 5_000,
          currency_iso: "USD"
        }
      }
    ]
  end

  let(:insurance_policies) do
    [
      {
        policy_id: "1000",
        insurance_product: insurance_product,
        hbx_enrollment_ids: [
          "1000"
        ],
        start_on: current_date.beginning_of_year,
        end_on: current_date.end_of_year,
        enrollments: insurance_policy_enrollments,
        aptc_csr_tax_households: aptc_csr_tax_households
      },
      {
        policy_id: "1000",
        insurance_product: insurance_product,
        hbx_enrollment_ids: [
          "1000"
        ],
        start_on: current_date.beginning_of_year,
        end_on: current_date.end_of_year,
        enrollments: insurance_policy_enrollments,
        aptc_csr_tax_households: aptc_csr_tax_households
      },
    ]
  end

  let(:insurance_product) do
    {
      name: "ABC plan",
      hios_plan_id: "123456",
      plan_year: 2023,
      coverage_type: "health",
      metal_level: "silver",
      market_type: "individual",
      ehb: 1.0
    }
  end

  let(:contract_holder) do
    {
      hbx_id: "1000595",
      person_name: person_name_1,
      encrypted_ssn: "yobheUbYUK2Abfc6lrq37YQCsPgBL8lLkw==\n",
      dob: current_date - 40.years,
      gender: "female",
      addresses: [
        {
          kind: "home",
          address_1: "S Street NW",
          address_2: "",
          address_3: "",
          city: "Awesome city",
          county_name: "Awesome county",
          state_abbreviation: "DC",
          zip_code: "20002"
        }
      ]
    }
  end

  let(:insurance_agreements) do
    [
      {
        plan_year: 2023,
        contract_holder: contract_holder,
        insurance_provider: insurance_provider,
        insurance_policies: insurance_policies
      }
    ]
  end

  let(:insurance_provider) do
    {
      title: "MAINE COMMUNITY HEALTH OPTIONS",
      hios_id: "123456",
      fein: "311705652",
      insurance_products: [insurance_product]
    }
  end

  let(:aptc_csr_tax_households) do
    [
      {
        covered_individuals: [
          {
            coverage_start_on: current_date.beginning_of_year,
            coverage_end_on: current_date.end_of_year,
            person: {
              hbx_id: "1000595",
              person_name: person_name_1,
              person_demographics: {
                gender: "female",
                encrypted_ssn: "yobheUbYUK2Abfc6lrq37YQCsPgBL8lLkw==\n",
                dob: current_date - 40.years
              },
              person_health: {},
              is_active: true,
              addresses: addresses,
              emails: [
                {
                  kind: "home",
                  address: "test@gmail.com"
                }
              ]
            },
            relation_with_primary: "self",
            filer_status: "tax_filer"
          }
        ],
        months_of_year: months_of_year,
        annual_premiums: annual_premiums
      }
    ]
  end

  let(:hbx_enrollment_members) do
    [
      {
        :family_member_reference => {
          :family_member_hbx_id => '1',
          :first_name => "John",
          :last_name => "Smith1",
          :person_hbx_id => "1000595",
          :dob => Date.new(1972, 4, 4)
        },
        :is_subscriber => true,
        :eligibility_date => Date.today,
        :coverage_start_on => Date.today
      },
      {
        :family_member_reference => {
          :family_member_hbx_id => '2',
          :first_name => "John",
          :last_name => "Smith2",
          :person_hbx_id => "476",
          :dob => Date.new(1978, 4, 4)
        },
        :is_subscriber => false,
        :eligibility_date => Date.today,
        :coverage_start_on => Date.today
      }
    ]
  end

  let(:product_reference) do
    {
      :is_csr => true,
      :individual_deductible => "700",
      :family_deductible => "1400",
      :hios_id => "41842DC0400010-01",
      :name => "BlueChoice silver1 2,000",
      :active_year => 2021,
      :is_dental_only => false,
      :metal_level => "silver",
      :benefit_market_kind => "aca_individual",
      :product_kind => "health",
      :issuer_profile_reference => issuer_profile_reference
    }
  end

  let(:issuer_profile_reference) do
    {
      :phone => "786-908-7789",
      :hbx_id => "bb35d006bd844d4c91b68983569dc676",
      :name => "Blue Cross Blue Shield",
      :abbrev => "ANTHM"
    }
  end

  let(:consumer_role_preference) do
    {
      :is_active => true,
      :is_applying_coverage => true,
      :is_applicant => true,
      :is_state_resident => true,
      :lawful_presence_determination => {},
      :citizen_status => "us_citizen"
    }
  end
end
