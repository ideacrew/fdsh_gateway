# frozen_string_literal: true

RequestEventMessage = {
  request_id: '00998877',
  ifsv_applicant: {
    person: {
      person_name: {
        PersonGivenName: 'Michael',
        PersonMiddleName: 'J',
        PersonSurName: 'Brady'
      },
      person_ssn_identification: {
        identification_id: '222131234'
      }
    },
    tax_filer_category_code: 'PRIMARY'
  }
}.freeze

ResponseEventMessage = {
  irs_response: {
    request_id: '00998877',
    household: {
      income: {
        income_amount: 0
      },
      applicant_verification: [
        {
          tax_return: {
            primary_tax_filer: {
              tin_identification: '222131234'
            },
            spouse_tax_filer: {
              tin_identification: '222131235'
            },
            tax_return_year: 2020,
            tax_return_filing_status_code: 0,
            tax_return_agi_amount: 0,
            tax_return_taxable_social_security_benefits_amount: 0,
            tax_return_total_exemptions_quantity: 0
          },
          response_metadata: [
            {
              response_code: 'response_code0',
              response_description_text: 'response_description_text0',
              tds_response_description_text: 'tds_response_description_text0'
            },
            {
              response_code: 'response_code1',
              response_description_text: 'response_description_text1',
              tds_response_description_text: 'tds_response_description_text1'
            }
          ]
        }
      ],
      dependent_verification: [
        {
          tax_return: {
            primary_tax_filer: {
              tin_identification: '222131238'
            },
            spouse_tax_filer_: {
              tin_identification: '222131239'
            },
            tax_return_year: 2020,
            tax_return_filing_status_code: 0,
            tax_return_agi_amount: 0,
            tax_return_taxable_social_security_benefits_amount: 0,
            tax_return_total_exemptions_quantity: 0
          },
          response_metadata: [
            {
              response_code: 'response_code4',
              response_description_text: 'response_description_text4',
              tds_response_description_text: 'tds_response_description_text4'
            },
            {
              response_code: 'response_code5',
              response_description_text: 'response_description_text5',
              tds_response_description_text: 'tds_response_description_text5'
            }
          ]
        },
        {
          tax_return: {
            primary_tax_filer: {
              tin_identification: '222131230'
            },
            spouse_tax_filer: {
              tin_identification: '222131231'
            },
            tax_return_year: 2020,
            tax_return_filing_status_code: 0,
            tax_returnMAGIAmount: 0,
            tax_return_taxable_social_security_benefits_amount: 0,
            tax_return_total_exemptions_quantity: 0
          },
          response_metadata: [
            {
              response_code: 'response_code6',
              response_description_text: 'response_description_text6',
              tds_response_description_text: 'tds_response_description_text6'
            },
            {
              response_code: 'response_code7',
              response_description_text: 'response_description_text7',
              tds_response_description_text: 'tds_response_description_text7'
            }
          ]
        }
      ]
    }
  }
}.freeze
# RSpec.shared_context('with events') {}
