# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Ridp
    module H139
      # This class takes AcaEntities::Families::Famlily as input and returns the secondary request.
      class TransformFamilyToSecondaryDetermination
        include Dry::Monads[:result, :do, :try]
        include AcaEntities::AppHelper

        # @param [Hash] opts The options to generate Ridp secondary Request Payload
        # @return [Dry::Monads::Result<]
        def call(family)
          valid_family                 = yield validate_family(family)
          primary_person               = yield fetch_primary_family_members_person(valid_family)
          secondary_request_evidence   = yield fetch_secondary_request_evidence(primary_person)
          secondary_request_values     = yield validate_secondary_request(secondary_request_evidence)
          secondary_request_entity     = yield create_secondary_request(secondary_request_evidence)

          Success(secondary_request_entity)
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

        def validate_secondary_request(evidence)
          result = AcaEntities::Fdsh::Ridp::H139::SecondaryRequestContract.new.call(evidence[:secondary_request])
          result.success? ? Success(result.to_h) : Failure(result.errors)
        end

        def create_secondary_request(values)
          Success(AcaEntities::Fdsh::Ridp::H139::SecondaryRequest.new(values))
        end
      end
    end
  end
end
