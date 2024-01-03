# frozen_string_literal: true

module Fdsh
  module Ridp
    module Rj139
      # This class takes AcaEntities::Families:Family as input and returns the ridp primary request hash.
      class TransformFamilyToPrimaryRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param params [Hash] The params to execute an FDSH RIDP Initial Verification Request
        # @option params [AcaEntities::Families::Family] :family
        # @return [Dry::Monads::Result]
        def call(params)
          family_hash = yield validate_family_json_hash(params)
          family = yield build_family(family_hash)
          person = yield fetch_primary_person(family)
          validated_person = yield validate_person(person)
          request_entity = yield build_request_entity(validated_person)

          Success(request_entity)
        end

        private

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

        def fetch_primary_person(family)
          primary_family_member =
            family.family_members.detect(&:is_primary_applicant)
          if primary_family_member
            Success(primary_family_member.person)
          else
            Failure('No Primary Applicant in family members')
          end
        end

        def validate_person(person)
          if person.is_a?(::AcaEntities::People::Person)
            Success(person)
          else
            Failure(
              "Invalid person, given value is not a ::AcaEntities::People::Person, input_value:#{person}"
            )
          end
        end

        def build_request_entity(person)
          ::AcaEntities::Fdsh::Ridp::Rj139::Operations::PersonToPrimaryRequest.new.call(person)
        end
      end
    end
  end
end