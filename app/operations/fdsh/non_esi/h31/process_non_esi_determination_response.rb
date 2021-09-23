# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module NonEsi
    module H31
      # This class takes happy mapper hash as input and returns
      class ProcessNonEsiDeterminationResponse
        include Dry::Monads[:result, :do, :try]
        include AcaEntities::AppHelper

        # @param [Hash] opts The options to process
        # @return [Dry::Monads::Result]
        def call(xml_response, params)
          parsed_xml         = yield process_xml(xml_response)
          response_params    = yield construct_params(parsed_xml)
          _response_activity = yield create_response_activity(response_params, params)
          valid_response     = yield validate_non_esi_response(response_params)
          non_esi_response   = yield create_non_esi_response(valid_response)

          Success(non_esi_response)
        end

        private

        def create_response_activity(response, params)
          activity_hash = {
            correlation_id: "esi_#{params[:correlation_id]}",
            command: "Fdsh::NonEsi::H31::ProcessNonEsiDeterminationResponse",
            event_key: params[:event_key],
            message: { response: response }
          }

          transaction_hash = { correlation_id: activity_hash[:correlation_id], activity: activity_hash }
          Try do
            Journal::Transactions::AddActivity.new.call(transaction_hash)
          end
        end

        def process_xml(xml_body)
          result = AcaEntities::Serializers::Xml::Fdsh::NonEsi::H31::VerifyNonEsiMecResponse.parse(xml_body, :single => true)
          Success(result)
        end

        def construct_params(parsed_xml)
          result_hash = {}
          if parsed_xml.IndividualResponseSet
            result_hash.merge!({ IndividualResponseSet: construct_individual_response(parsed_xml.IndividualResponseSet) })
          end
          result_hash.merge!({ ResponseMetadata: construct_response_metadata(parsed_xml.ResponseMetadata) }) if parsed_xml.ResponseMetadata

          Success(result_hash)
        end

        def construct_individual_response(individual_response_set)
          {
            IndividualResponses: individual_response_set.IndividualResponses.collect do |individual_response|
              {
                Applicant: construct_request_applicant(individual_response.Applicant),
                PartialResponseIndicator: individual_response.PartialResponseIndicator,
                OtherCoverages: construct_other_coverages(individual_response)
              }
            end
          }
        end

        def construct_other_coverages(response)
          return unless response.OtherCoverages
          response.OtherCoverages.collect do |o_coverage|
            {
              OrganizationCode: o_coverage.OrganizationCode,
              ResponseMetadata: construct_response_metadata(o_coverage.ResponseMetadata),
              MECCoverage: construct_mec_coverage(o_coverage.MECCoverage)
            }
          end
        end

        def construct_mec_coverage(mec_coverage)
          return unless mec_coverage
          {
            LocationStateUSPostalServiceCode: mec_coverage.LocationStateUSPostalServiceCode,
            MECVerificationCode: mec_coverage.MECVerificationCode,
            Insurances: mec_coverage.Insurances.collect do |insurance|
              {
                InsuranceEffectiveDate: insurance.InsuranceEffectiveDate&.date,
                InsuranceEndDate: insurance.InsuranceEndDate&.date
              }
            end
          }
        end

        def construct_request_applicant(applicant)
          {
            PersonSSNIdentification: applicant.PersonSSNIdentification,
            PersonName: construct_person_name(applicant.PersonName),
            PersonBirthDate: applicant.PersonBirthDate.date,
            PersonSexCode: applicant.PersonSexCode
          }
        end

        def construct_person_name(person)
          {
            PersonGivenName: person&.PersonGivenName,
            PersonMiddleName: person&.PersonMiddleName,
            PersonSurName: person&.PersonSurName,
            PersonNameSuffixText: person&.PersonNameSuffixText
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
        def validate_non_esi_response(payload)
          result = ::AcaEntities::Fdsh::NonEsi::H31::VerifyNonESIMECResponseContract.new.call(payload)

          if result.success?
            Success(result)
          else
            Failure("Invalid response, #{result.errors.to_h}")
          end
        end

        def create_non_esi_response(value)
          Success(::AcaEntities::Fdsh::NonEsi::H31::VerifyNonESIMECResponse.new(value.to_h))
        end
      end
    end
  end
end
