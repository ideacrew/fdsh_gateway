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
        def call(family)
          valid_family                 = yield validate_family(family)
          primary_person               = yield fetch_primary_family_members_person(valid_family)
          secondary_request_evidence   = yield fetch_secondary_request_evidence(primary_person)
          secondary_request_json       = yield fetch_secondary_request(secondary_request_evidence)

          Success(secondary_request_json)
        end

        private

        # Validate input object
        def validate_family(family)
          if family.is_a?(::AcaEntities::Families::Family)
            Success(family)
          else
            Failure("Invalid Family, given value is not a ::AcaEntities::Families::Family, input_value:#{family}")
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
