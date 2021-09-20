# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'digest'
require 'zip'

module Fdsh
  module Rrv
    module Medicare
      module Response
        # This class create a rrv medicare request manifest file
        class ConstructMedicareResponse
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          def call(payload)
            response_hash      = yield construct_params(payload)
            valid_response     = yield validate_rrv_medicare_response(response_hash)
            medicare_response   = yield create_rrv_medicare_response(valid_response)

            Success(medicare_response)
          end

          private

          def construct_params(payload)
            if payload.IndividualResponses.present?
              result_hash = {
                IndividualResponses: construct_individual_response(payload.IndividualResponses.IndividualResponses)
              }
            end

            Success(result_hash)
          end

          def validate_rrv_medicare_response(response_hash)
            result = ::AcaEntities::Fdsh::Rrv::Medicare::EesDshBatchResponseDataContract.new.call(response_hash)

            if result.success?
              Success(result)
            else
              Failure("Invalid response, #{result.errors.to_h}")
            end
          end

          def create_rrv_medicare_response(value)
            Success(::AcaEntities::Fdsh::Rrv::Medicare::EesDshBatchResponseData.new(value.to_h))
          end

          def construct_individual_response(individual_responses)
            individual_responses.collect do |response|
              {
                PersonSSNIdentification: response.PersonSSNIdentification,
                Insurances: construct_insurances(response.Insurances),
                OrganizationResponseCode: response.OrganizationResponseCode,
                OrganizationResponseCodeText: response.OrganizationResponseCodeText
              }

            end
          end

          def construct_insurances(insurances)
            insurances.collect do |insurance|
              insurance_hash = {}

              insurance_hash.merge!(InsuranceEffectiveDate: insurance.InsuranceEffectiveDate) if insurance.InsuranceEffectiveDate.present?
              insurance_hash.merge!(InsuranceEndDate: insurance.InsuranceEndDate) if insurance.InsuranceEndDate.present?

              insurance_hash
            end
          end
        end
      end
    end
  end
end
