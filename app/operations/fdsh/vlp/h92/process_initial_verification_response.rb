# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Vlp
    module H92
      # This class takes happy mapper hash as input and returns
      class ProcessInitialVerificationResponse
        include Dry::Monads[:result, :do, :try]
        include AcaEntities::AppHelper

        XMLNS = {
          soap: "http://www.w3.org/2003/05/soap-envelope"
        }.freeze

        # @param [Hash] opts The options to process
        # @return [Dry::Monads::Result]
        def call(xml_response)
          parsed_xml         = yield process_xml(xml_response)
          params             = yield construct_params(parsed_xml)
          valid_response     = yield validate_initial_response(params)
          primary_response   = yield create_primary_response(valid_response)

          Success(primary_response)
        end

        private

        def process_xml(xml_body)
          result = AcaEntities::Serializers::Xml::Fdsh::Vlp::H92::InitialVerificationResponse.parse(xml_body, :single => true)
          Success(result)
        end

        def construct_params(parsed_xml)
          result_hash = {
            ResponseMetadata: construct_response_metadata(parsed_xml&.ResponseMetadata),
            InitialVerificationResponseSet: get_individual_verification_response_set(parsed_xml.InitialVerificationResponseSet)
          }

          Success(result_hash)
        end

        def get_individual_verification_response_set(response_set)
          {
            InitialVerificationIndividualResponses: response_set.InitialVerificationIndividualResponses.collect do |individual_response|
              {
                ResponseMetadata: construct_response_metadata(individual_response&.ResponseMetadata),
                ArrayOfErrorResponseMetadata: construct_error_response_metadata(individual_response.ArrayOfErrorResponseMetadata),
                LawfulPresenceVerifiedCode: individual_response.LawfulPresenceVerifiedCode,
                InitialVerificationIndividualResponseSet: get_individual_response_set(individual_response.InitialVerificationIndividualResponseSet)
              }
            end
          }
        end

        # rubocop:disable Metrics/MethodLength
        def get_individual_response_set(individual_response_set)
          {
            CaseNumber: individual_response_set&.CaseNumber,
            NonCitLastName: individual_response_set&.NonCitLastName,
            NonCitFirstName: individual_response_set&.NonCitFirstName,
            NonCitMiddleName: individual_response_set&.NonCitMiddleName,
            NonCitBirthDate: individual_response_set&.NonCitBirthDate,
            NonCitEntryDate: individual_response_set&.NonCitEntryDate,
            AdmittedToDate: individual_response_set&.AdmittedToDate,
            AdmittedToText: individual_response_set&.AdmittedToText,
            NonCitCountryBirthCd: individual_response_set&.NonCitCountryBirthCd,
            NonCitCountryCitCd: individual_response_set&.NonCitCountryCitCd,
            NonCitCoaCode: individual_response_set&.NonCitCoaCode,
            NonCitProvOfLaw: individual_response_set&.NonCitProvOfLaw,
            NonCitEadsExpireDate: individual_response_set&.NonCitEadsExpireDate,
            EligStatementCd: individual_response_set&.EligStatementCd,
            EligStatementTxt: individual_response_set&.EligStatementTxt,
            IAVTypeCode: individual_response_set&.IAVTypeCode,
            IAVTypeTxt: individual_response_set&.IAVTypeTxt,
            WebServSftwrVer: individual_response_set&.WebServSftwrVer,
            GrantDate: individual_response_set&.GrantDate,
            GrantDateReasonCd: individual_response_set&.GrantDateReasonCd,
            SponsorDataFoundIndicator: individual_response_set&.SponsorDataFoundIndicator,
            ArrayOfSponsorshipData: construct_sponsorship_data(individual_response_set&.ArrayOfSponsorshipData),
            SponsorshipReasonCd: individual_response_set&.SponsorshipReasonCd,
            AgencyAction: individual_response_set&.AgencyAction,
            FiveYearBarApplyCode: individual_response_set&.FiveYearBarApplyCode,
            QualifiedNonCitizenCode: individual_response_set&.QualifiedNonCitizenCode,
            FiveYearBarMetCode: individual_response_set&.FiveYearBarMetCode,
            USCitizenCode: individual_response_set&.USCitizenCode
          }
        end
        # rubocop:enable Metrics/MethodLength

        def construct_sponsorship_data(sponsorship_data_array)
          return nil unless sponsorship_data_array

          sponsorship_data_array.SponsorshipData.collect do |sponsorship_data|
            {
              LastName: sponsorship_data.LastName,
              FirstName: sponsorship_data.FirstName,
              MiddleName: sponsorship_data.MiddleName,
              Addr1: sponsorship_data.Addr1,
              Addr2: sponsorship_data.Addr2,
              City: sponsorship_data.City,
              StateProvince: sponsorship_data.StateProvince,
              ZipPostalCode: sponsorship_data.ZipPostalCode,
              SSN: sponsorship_data.SSN,
              CountryCode: sponsorship_data.CountryCode,
              CountryName: sponsorship_data.CountryName
            }
          end
        end

        def construct_response_metadata(metadata)
          {
            ResponseCode: metadata&.ResponseCode,
            ResponseDescriptionText: metadata&.ResponseDescriptionText,
            TDSResponseDescriptionText: metadata&.TDSResponseDescriptionText
          }
        end

        def construct_error_response_metadata(error_metadata_array)
          return nil unless error_metadata_array

          error_metadata_array.ErrorResponseMetadatas.collect do |error_metadata|
            {
              ErrorResponseCode: error_metadata&.ErrorResponseCode,
              ErrorResponseDescriptionText: error_metadata&.ErrorResponseDescriptionText,
              ErrorTDSResponseDescriptionText: error_metadata&.ErrorTDSResponseDescriptionText
            }
          end
        end

        # Validate input object
        def validate_initial_response(payload)
          result = ::AcaEntities::Fdsh::Vlp::H92::InitialVerificationResponseContract.new.call(payload)

          if result.success?
            Success(result)
          else
            Failure("Invalid response, #{result.errors.to_h}")
          end
        end

        def create_primary_response(value)
          Success(::AcaEntities::Fdsh::Vlp::H92::InitialVerificationResponse.new(value.to_h))
        end
      end
    end
  end
end
