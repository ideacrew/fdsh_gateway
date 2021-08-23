# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Ssa
    module H3
      # This class takes happy mapper hash as input and returns
      class ProcessSsaVerificationResponse
        include Dry::Monads[:result, :do, :try]
        include AcaEntities::AppHelper

        # @param [Hash] opts The options to process
        # @return [Dry::Monads::Result]
        def call(xml_response)
          parsed_xml         = yield process_xml(xml_response)
          params             = yield construct_params(parsed_xml)
          valid_response     = yield validate_ssa_composite_response(params)
          primary_response   = yield create_primary_response(valid_response)

          Success(primary_response)
        end

        private

        def process_xml(xml_body)
          result = AcaEntities::Serializers::Xml::Fdsh::Ssa::H3::SSACompositeResponse.parse(xml_body, :single => true)
          Success(result)
        end

        def construct_params(parsed_xml)
          result_hash = {
            ResponseMetadata: construct_response_metadata(parsed_xml&.ResponseMetadata),
            SSACompositeIndividualResponses: get_composite_individual_responses(parsed_xml.SSACompositeIndividualResponses)
          }

          Success(result_hash)
        end

        def get_composite_individual_responses(individual_responses)
          return nil unless individual_responses

          individual_responses.collect do |individual_response|
            {
              ResponseMetadata: construct_response_metadata(individual_response&.ResponseMetadata),
              PersonSSNIdentification: individual_response&.PersonSSNIdentification,
              SSAResponse: construct_ssa_response(individual_response&.SSAResponse)
            }
          end
        end

        def construct_ssa_response(ssa_response)
          return nil unless ssa_response

          {
            SSNVerificationIndicator: ssa_response&.SSNVerificationIndicator,
            DeathConfirmationCode: ssa_response&.DeathConfirmationCode,
            PersonUSCitizenIndicator: ssa_response&.PersonUSCitizenIndicator,
            PersonIncarcerationInformationIndicator: ssa_response&.PersonIncarcerationInformationIndicator,
            SSATitleIIMonthlyIncomeInformationIndicator: ssa_response&.SSATitleIIMonthlyIncomeInformationIndicator,
            SSATitleIIAnnualIncomeInformationIndicator: ssa_response&.SSATitleIIAnnualIncomeInformationIndicator,
            SSAQuartersOfCoverageInformationIndicator: ssa_response&.SSAQuartersOfCoverageInformationIndicator,
            SSAIncarcerationInformation: construct_incarceration_info(ssa_response&.SSAIncarcerationInformation),
            SSATitleIIMonthlyIncome: construct_monthly_income(ssa_response&.SSATitleIIMonthlyIncome),
            SSATitleIIYearlyIncome: construct_yearly_income(ssa_response&.SSATitleIIYearlyIncome),
            SSAQuartersOfCoverage: construct_quarterly_coverage(ssa_response&.SSAQuartersOfCoverage)
          }
        end

        def construct_quarterly_coverage(coverage)
          return nil unless coverage

          {
            LifeTimeQuarterQuantity: coverage.LifeTimeQuarterQuantity,
            QualifyingYearAndQuarter: {
              QualifyingYear: coverage.QualifyingYearAndQuarter&.QualifyingYear,
              QualifyingQuarter: coverage.QualifyingYearAndQuarter&.QualifyingQuarter
            }
          }
        end

        def construct_yearly_income(income)
          return nil unless income

          {
            TitleIIRequestedYearInformation: {
              IncomeDate: income.TitleIIRequestedYearInformation&.IncomeDate,
              YearlyIncomeAmount: income.TitleIIRequestedYearInformation&.YearlyIncomeAmount
            }
          }
        end

        def construct_monthly_income(income)
          return nil unless income

          {
            PersonDisabledIndicator: income.PersonDisabledIndicator,
            OngoingMonthlyBenefitCreditedAmount: income.OngoingMonthlyBenefitCreditedAmount,
            OngoingMonthlyOverpaymentDeductionAmount: income.OngoingMonthlyOverpaymentDeductionAmount,
            OngoingPaymentInSuspenseIndicator: income.OngoingPaymentInSuspenseIndicator,
            RequestedMonthInformation: construct_requested_month_info(income.RequestedMonthInformation),
            RequestedMonthMinusOneInformation: construct_requested_month_info(income.RequestedMonthMinusOneInformation),
            RequestedMonthMinusTwoInformation: construct_requested_month_info(income.RequestedMonthMinusTwoInformation),
            RequestedMonthMinusThreeInformation: construct_requested_month_info(income.RequestedMonthMinusThreeInformation)
          }
        end

        def construct_requested_month_info(monthly_info)
          return nil unless monthly_info

          {
            IncomeMonthYear: monthly_info&.IncomeMonthYear,
            BenefitCreditedAmount: monthly_info&.BenefitCreditedAmount,
            OverpaymentDeductionAmount: monthly_info&.OverpaymentDeductionAmount,
            PriorMonthAccrualAmount: monthly_info&.PriorMonthAccrualAmount,
            ReturnedCheckAmount: monthly_info&.ReturnedCheckAmount,
            PaymentInSuspenseIndicator: monthly_info&.PaymentInSuspenseIndicator
          }
        end

        def construct_incarceration_info(incarceration_info)
          return nil unless incarceration_info

          {
            PrisonerIdentification: incarceration_info.PrisonerIdentification,
            PrisonerConfinementDate: incarceration_info.PrisonerConfinementDate,
            ReportingPersonText: incarceration_info.ReportingPersonText,
            SupervisionFacility: construct_facility_info(incarceration_info.SupervisionFacility),
            InmateStatusIndicator: incarceration_info.InmateStatusIndicator
          }
        end

        def construct_facility_info(facility)
          return nil unless facility

          {
            FacilityName: facility.FacilityName,
            FacilityLocation: construct_facility_location(facility.FacilityLocation),
            FacilityContactInformation: construct_facility_contact_info(facility.FacilityContactInformation),
            FacilityCategoryCode: facility.FacilityCategoryCode
          }
        end

        def construct_facility_location(location)
          return nil unless location

          {
            LocationStreet: location&.LocationStreet,
            LocationCityName: location&.LocationCityName,
            LocationStateUSPostalServiceCode: location&.LocationStateUSPostalServiceCode,
            LocationPostalCode: location&.LocationPostalCode,
            LocationPostalExtensionCode: location&.LocationPostalExtensionCode
          }
        end

        def construct_facility_contact_info(contact_info)
          return nil unless contact_info

          {
            PersonFullName: contact_info.PersonFullName,
            ContactTelephoneNumber: contact_info.ContactTelephoneNumber,
            ContactFaxNumber: contact_info.ContactFaxNumber
          }
        end

        def construct_response_metadata(metadata)
          return nil unless metadata

          {
            ResponseCode: metadata&.ResponseCode,
            ResponseDescriptionText: metadata&.ResponseDescriptionText,
            TDSResponseDescriptionText: metadata&.TDSResponseDescriptionText
          }
        end

        # Validate input object
        def validate_ssa_composite_response(payload)
          result = ::AcaEntities::Fdsh::Ssa::H3::SSACompositeResponseContract.new.call(payload)

          if result.success?
            Success(result)
          else
            Failure("Invalid response, #{result.errors.to_h}")
          end
        end

        def create_primary_response(value)
          Success(::AcaEntities::Fdsh::Ssa::H3::SSACompositeResponse.new(value.to_h))
        end
      end
    end
  end
end
