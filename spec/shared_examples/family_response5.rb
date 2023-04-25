# frozen_string_literal: true

RSpec.shared_context 'family response with one policy coverage_start_on as feb 1', shared_context: :metadata do
  let(:verification_types2) do
    [{ type_name: 'American Indian Status', validation_status: 'outstanding', due_date: Date.today + 45.days }]
  end

  let(:current_date2) { Date.today }
  let(:family_hash2) do
    {
      documents_needed: true,
      hbx_id: '43456',
      family_members: [family_member_22, family_member_12],
      households: households2
    }
  end

  let(:consumer_role_22) do
    {
      is_applying_coverage: true,
      contact_method: contact_method2,
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

  let(:consumer_role_12) do
    {
      is_applying_coverage: true,
      contact_method: contact_method2,
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

  let(:contact_method2) { 'Paper, Electronic and Text Message communications' }
  let(:person_name_12) { { first_name: 'John', last_name: 'Smith' } }
  let(:city2) { 'Augusta' }
  let(:family_member_12) do
    {
      is_primary_applicant: true,
      person: {
        hbx_id: '22338800595',
        person_name: person_name_12,
        person_demographics: {
          ssn: '784796992',
          gender: 'male',
          dob: Date.new(1972, 4, 4),
          is_incarcerated: false
        },
        consumer_role: consumer_role_12,
        person_health: { is_tobacco_user: 'unknown' },
        is_active: true,
        is_disabled: false,
        addresses: [{ kind: 'mailing', address_1: '742 Washington Ave, 1', state: 'ME', city: city2, zip: '67662' }],
        verification_types: verification_types2
      }
    }
  end

  let(:family_member_22) do
    {
      is_primary_applicant: false,
      person: {
        hbx_id: '476',
        person_name: { first_name: 'John', last_name: 'Smith2' },
        person_demographics: {
          ssn: '784796993',
          gender: 'male',
          dob: Date.new(1978, 4, 4),
          is_incarcerated: false
        },
        consumer_role: consumer_role_22,
        person_health: { is_tobacco_user: 'unknown' },
        is_active: true,
        is_disabled: false,
        addresses: [{ kind: 'mailing', address_1: '742 Washington Ave, 1', state: 'ME', city: city2, zip: '67662' }],
        verification_types: verification_types2
      }
    }
  end

  let(:households2) do
    [
      {
        start_date: Date.today, is_active: true, irs_group_reference: {},
        coverage_households: [
          { is_immediate_family: true, coverage_household_members: [{ is_subscriber: true }] },
          { is_immediate_family: false, coverage_household_members: [] }
        ],
        hbx_enrollments: hbx_enrollments2, insurance_agreements: insurance_agreements2
      }
    ]
  end

  let(:hbx_enrollments2) do
    [
      {
        is_receiving_assistance: true,
        effective_on: Date.today,
        aasm_state: 'coverage_selected',
        applied_aptc_amount: { cents: BigDecimal(44_500), currency_iso: 'USD' },
        market_place_kind: 'individual',
        total_premium: 445.09,
        enrollment_period_kind: 'open_enrollment',
        product_kind: 'health',
        hbx_enrollment_members: hbx_enrollment_members2,
        product_reference: product_reference2,
        issuer_profile_reference: issuer_profile_reference2,
        consumer_role_reference: consumer_role_preference2
      }
    ]
  end

  let(:months_of_year2) do
    [
      {
        month: 'January',
        coverage_information: {
          tax_credit: { cents: 500.0, currency_iso: 'USD' },
          total_premium: { cents: 50_000, currency_iso: 'USD' },
          slcsp_benchmark_premium: { cents: 50_000, currency_iso: 'USD' }
        }
      },
      {
        month: 'February',
        coverage_information: {
          tax_credit: { cents: 500.0, currency_iso: 'USD' },
          total_premium: { cents: 50_000, currency_iso: 'USD' },
          slcsp_benchmark_premium: { cents: 50_000, currency_iso: 'USD' }
        }
      }
    ]
  end

  let(:annual_premiums2) do
    {
      tax_credit: { cents: 99_000, currency_iso: 'USD' },
      total_premium: { cents: 990_000, currency_iso: 'USD' },
      slcsp_benchmark_premium: { cents: 990_000, currency_iso: 'USD' }
    }
  end

  let(:addresses2) do
    [
      {
        kind: 'home', address_1: '742 Washington Ave, 1',
        address_2: '742 Washington Ave, 2', address_3: '',
        city: city2, county_name: 'Awesome county',
        state: 'DC', zip: '20002'
      }
    ]
  end

  let(:insurance_policy_enrollments2) do
    [
      {
        start_on: current_date2.beginning_of_year,
        subscriber: {
          member: {
            hbx_id: '22338800595',
            member_id: '22338800595',
            person_name: person_name_12
          },
          dob: '',
          gender: 'male',
          addresses: [
            {
              kind: 'home',
              address_1: '742 Washington Ave, 1',
              address_2: '742 Washington Ave, 2',
              address_3: '',
              city: city2,
              county_name: 'Awesome county',
              state: 'DC',
              zip: '20002'
            }
          ],
          emails: [{ kind: 'home', address: 'test@gmail.com' }]
        },
        dependents: [],
        total_premium_amount: { cents: 50_000, currency_iso: 'USD' },
        tax_households: [
          {
            hbx_id: '828762',
            tax_household_members: [
              {
                family_member_reference: {
                  family_member_hbx_id: '22338800595',
                  relation_with_primary: 'self'
                },
                tax_filer_status: 'tax_filer',
                is_subscriber: true
              }
            ]
          }
        ],
        total_premium_adjustment_amount: { cents: 5_000, currency_iso: 'USD' }
      }
    ]
  end

  let(:carrier_policy_id2) { 'carrier_policy_id' }
  let(:policy_aasm_state2) { 'submitted' }
  let(:policy_id2) { '103200' }

  let(:insurance_policies2) do
    [
      {
        aasm_state: policy_aasm_state2,
        policy_id: policy_id2,
        carrier_policy_id: carrier_policy_id2,
        insurance_product: insurance_product2,
        hbx_enrollment_ids: ['1000'],
        start_on: current_date2.beginning_of_year,
        end_on: current_date2.end_of_year,
        enrollments: insurance_policy_enrollments2,
        aptc_csr_tax_households: aptc_csr_tax_households2
      }
    ]
  end

  let(:insurance_product_metal_level2) { 'silver' }
  let(:coverage_type2) { 'health' }

  let(:insurance_product2) do
    {
      name: 'ABC plan',
      hios_plan_id: '123456',
      plan_year: current_date2.year,
      coverage_type: coverage_type2,
      metal_level: insurance_product_metal_level2,
      market_type: 'individual',
      ehb: 1.0
    }
  end

  let(:contract_holder2) do
    {
      hbx_id: '22338800595',
      person_name: person_name_12,
      encrypted_ssn: 'yobheUbYUK2Abfc6lrq37YQCsPgBL8lLkw==\n',
      dob: current_date2 - 40.years,
      gender: 'female',
      addresses: [
        {
          kind: 'home',
          address_1: '742 Washington Ave, 1',
          address_2: '742 Washington Ave, 2',
          address_3: '',
          city: city2,
          county_name: 'Awesome county',
          state_abbreviation: 'DC',
          zip_code: '20002'
        }
      ]
    }
  end

  let(:insurance_agreements2) do
    [
      {
        plan_year: current_date2.year,
        contract_holder: contract_holder2,
        insurance_provider: insurance_provider2,
        insurance_policies: insurance_policies2
      }
    ]
  end

  let(:insurance_provider2) do
    {
      title: 'MAINE COMMUNITY HEALTH OPTIONS',
      hios_id: '123456', fein: '311705652',
      insurance_products: [insurance_product2]
    }
  end

  let(:aptc_csr_tax_households2) do
    [
      {
        hbx_assigned_id: '82876288',
        primary_tax_filer_hbx_id: '82876288',
        tax_household_members: [
          {
            family_member_reference: {
              family_member_hbx_id: '1',
              first_name: 'John',
              last_name: 'Smith1',
              person_hbx_id: '22338800595',
              dob: Date.new(1972, 4, 4)
            }
          },
          {
            family_member_reference: {
              family_member_hbx_id: '2',
              first_name: 'John',
              last_name: 'Smith2',
              person_hbx_id: '476',
              dob: Date.new(1978, 4, 4)
            }
          }
        ],
        covered_individuals: [
          {
            coverage_start_on: Date.new(current_date2.year, 2),
            coverage_end_on: current_date2.end_of_year,
            person: {
              hbx_id: '22338800595',
              person_name: person_name_12,
              person_demographics: {
                gender: 'female',
                encrypted_ssn: 'yobheUbYUK2Abfc6lrq37YQCsPgBL8lLkw==\n',
                dob: current_date2 - 40.years
              },
              person_health: {},
              is_active: true,
              addresses: addresses2,
              emails: [{ kind: 'home', address: 'test@gmail.com' }]
            },
            relation_with_primary: 'self',
            filer_status: 'tax_filer'
          }
        ],
        months_of_year: months_of_year2,
        annual_premiums: annual_premiums2
      }
    ]
  end

  let(:hbx_enrollment_members2) do
    [
      {
        family_member_reference: {
          family_member_hbx_id: '1',
          first_name: 'John',
          last_name: 'Smith1',
          person_hbx_id: '22338800595',
          dob: Date.new(1972, 4, 4)
        },
        is_subscriber: true,
        eligibility_date: Date.today,
        coverage_start_on: Date.today
      },
      {
        family_member_reference: {
          family_member_hbx_id: '2',
          first_name: 'John',
          last_name: 'Smith2',
          person_hbx_id: '476',
          dob: Date.new(1978, 4, 4)
        },
        is_subscriber: false,
        eligibility_date: Date.today,
        coverage_start_on: Date.today
      }
    ]
  end

  let(:product_metal_level2) { 'silver' }

  let(:product_reference2) do
    {
      is_csr: true,
      individual_deductible: '700',
      family_deductible: '1400',
      hios_id: '41842DC0400010-01',
      name: 'BlueChoice silver1 2,000',
      active_year: current_date2.year,
      is_dental_only: false,
      metal_level: product_metal_level2,
      benefit_market_kind: 'aca_individual',
      product_kind: 'health',
      issuer_profile_reference: issuer_profile_reference2
    }
  end

  let(:issuer_profile_reference2) do
    {
      phone: '786-908-7789',
      hbx_id: 'bb35d006bd844d4c91b68983569dc676',
      name: 'Blue Cross Blue Shield',
      abbrev: 'ANTHM'
    }
  end

  let(:consumer_role_preference2) do
    {
      is_active: true,
      is_applying_coverage: true,
      is_applicant: true,
      is_state_resident: true,
      lawful_presence_determination: {},
      citizen_status: 'us_citizen'
    }
  end
end
