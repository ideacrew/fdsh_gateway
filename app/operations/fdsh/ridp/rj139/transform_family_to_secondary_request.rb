# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Ridp
    module Rj139
      # This class takes AcaEntities::Families:Family as input and returns the ridp primary request hash.
      class TransformFamilyToSecondaryRequest
        include Dry::Monads[:result, :do, :try]
        include AcaEntities::AppHelper

        # @param [Hash] opts The options to generate Ridp secondary Request Payload
        # @return [Dry::Monads::Result<]
        def call(params)
          json_hash = yield parse_json(params)
          family_hash = yield validate_family_json_hash(json_hash)
          family = yield build_family(family_hash)
          primary_person               = yield fetch_primary_family_members_person(family)
          secondary_request_evidence   = yield fetch_secondary_request_evidence(primary_person)
          require 'pry'; binding.pry
          secondary_request_json       = yield fetch_secondary_request(secondary_request_evidence)

          Success(secondary_request_json)
        end

        private

        def parse_json(json_string)
          parsing_result = Try do
            JSON.parse(json_string, :symbolize_names => true)
          end
          parsing_result.or do
            Failure(:invalid_json)
          end
        end

        def validate_family_json_hash(json_hash)
          validation_result = AcaEntities::Contracts::Families::FamilyContract.new.call(json_hash)

          validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
        end

        def build_family(family_hash)
          creation_result = Try do
            AcaEntities::Families::Family.new(family_hash)
          end

          creation_result.or do |e|
            Failure(e)
          end
        end

        def fetch_primary_family_members_person(family)
          primary_family_member = family.family_members.detect(&:is_primary_applicant)
          if primary_family_member
            Success(primary_family_member.person)
          else
            Failure("No Primary Applicant in family members")
          end
        end

        def fetch_secondary_request_evidence(primary_person)
          Try do
            primary_person.user.attestations.first.attestations[:ridp_attestation][:evidences].detect do |evidence|
              evidence[:secondary_request].present?
            end
          end
        end

        def fetch_secondary_request(evidence)
          request = evidence[:secondary_request]
          # need to build this operation in aca_entities!
          ::AcaEntities::Fdsh::Ridp::Rj139::Operations::EvidenceToSecondaryRequest.new.call(request)
        end
      end
    end
  end
end
