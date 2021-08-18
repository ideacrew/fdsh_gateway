# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Esi
    module H14
      # This class takes happy mapper hash as input and returns
      class ProcessEsiDeterminationResponse
        include Dry::Monads[:result, :do, :try]
        include AcaEntities::AppHelper

        # @param [Hash] opts The options to process
        # @return [Dry::Monads::Result]
        def call(xml_response, params)
          _response_activity = yield create_response_activity(xml_response, params)
          parsed_xml         = yield process_xml(xml_response)
          params             = yield construct_params(parsed_xml)
          valid_response     = yield validate_esi_response(params)
          esi_response       = yield create_esi_response(valid_response)

          Success(esi_response)
        end

        private

        def create_response_activity(response, params)
          activity_hash = {
            correlation_id: "esi_#{params[:correlation_id]}",
            command: "Fdsh::Esi::H14::ProcessEsiDeterminationResponse",
            event_key: params[:event_key],
            message: { response: response }
          }

          Try do
            Journal::Transactions::AddActivity.new.call(activity_hash)
          end
        end

        def process_xml(xml_body)
          result = AcaEntities::Serializers::Xml::Fdsh::Esi::H14::EsiMecResponse.parse(xml_body, :single => true)
          Success(result)
        end

        def construct_params(parsed_xml)
          result_hash = {}
          if parsed_xml.ApplicantResponseSet
            result_hash.merge!({ ApplicantResponseSet: construct_applicant_response(parsed_xml.ApplicantResponseSet) })
          end
          result_hash.merge!({ ResponseMetadata: construct_response_metadata(parsed_xml.ResponseMetadata) }) if parsed_xml.ResponseMetadata

          Success(result_hash)
        end

        def construct_applicant_response(applicant_response_set)
          {
            ApplicantResponses: applicant_response_set.ApplicantResponses.collect do |applicant_response|
              {
                ResponseMetadata: construct_response_metadata(applicant_response.ResponseMetadata),
                ResponsePerson: construct_person_identification(applicant_response.ResponsePerson),
                ApplicantMECInformation: construct_mec_information(applicant_response.ApplicantMECInformation)
              }
            end
          }
        end

        def construct_person_identification(person)
          {
            PersonSSNIdentification: {
              IdentificationID: person.PersonSSNIdentification.IdentificationID
            }
          }
        end

        def construct_mec_information(mec_information)
          return unless mec_information
          {
            InsuranceApplicantResponse: construct_insurance_applicant_response(mec_information.InsuranceApplicantResponse),
            InconsistencyIndicator: mec_information.InconsistencyIndicator,
            MonthlyPremiumAmount: construct_monthly_premium_amount(mec_information.MonthlyPremiumAmount)
          }
        end

        def construct_monthly_premium_amount(monthly_premium)
          return unless monthly_premium
          premium_hash = {}

          if monthly_premium.EmployeePremiumAmount
            premium_hash.merge!({ EmployeePremiumAmount: { InsurancePremiumAmount: monthly_premium.EmployeePremiumAmount&.InsurancePremiumAmount } })
          end

          if monthly_premium.FamilyPremiumAmount
            premium_hash.merge!({ FamilyPremiumAmount: { InsurancePremiumAmount: monthly_premium.FamilyPremiumAmount&.InsurancePremiumAmount } })
          end

          premium_hash
        end

        def construct_insurance_applicant_response(response)
          return unless response
          {
            InsuranceApplicantRequestedCoverage: construct_requested_coverage(response.InsuranceApplicantRequestedCoverage),
            InsuranceApplicantEligibleEmployerSponsoredInsuranceIndicator: response.InsuranceApplicantEligibleEmployerSponsoredInsuranceIndicator,
            InsuranceApplicantInsuredIndicator: response.InsuranceApplicantInsuredIndicator
          }
        end

        def construct_requested_coverage(requested_coverage)
          {
            StartDate: requested_coverage.StartDate.date,
            EndDate: requested_coverage.EndDate.date
          }
        end

        def construct_response_metadata(metadata)
          return nil unless metadata

          {
            ResponseCode: metadata&.ResponseCode,
            ResponseDescriptionText: metadata&.ResponseDescriptionText
          }
        end

        # Validate input object
        def validate_esi_response(payload)
          result = ::AcaEntities::Fdsh::Esi::H14::ESIMECResponseContract.new.call(payload)

          if result.success?
            Success(result)
          else
            Failure("Invalid response, #{result.errors.to_h}")
          end
        end

        def create_esi_response(value)
          Success(::AcaEntities::Fdsh::Esi::H14::ESIMECResponse.new(value.to_h))
        end
      end
    end
  end
end
