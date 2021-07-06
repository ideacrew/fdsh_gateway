# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
    module Ridp
      module H139
        # This class takes AcaEntities::Families::Famlily as input and returns the ridp primary request hash.
        class TransformFamilyToPrimaryDetermination
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          # @param params [Hash] The params to execute an FDSH RIDP Primary Determination Request
          # @option params [AcaEntities::Families::Family] :family
          # @return [Dry::Monads::Result]
          def call(params)
            family = yield validate_family(params)
            person = yield fetch_primary_person(family)
            request = yield build_request(person)
            validated_request = yield validate_primary_request(request)
            request_entity = yield primary_request_entity(validated_request)

            Success(request_entity)
          end

          private


          # Validate input object
          def validate_family(family)
            if family.is_a?(::AcaEntities::Families::Family)
              Success(family)
            else
              Failure(
                "Invalid Family, given value is not a ::AcaEntities::Families::Family, input_value:#{family}"
              )
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

          # Transform Person params To PrimaryRequest Contract params
          def build_request(person)
            input_hash =
              person.to_h.merge(
                {
                  home_address: person.home_address.to_h,
                  home_phone: person.home_phone.to_h
                }
              )
            ::AcaEntities::Fdsh::Transformers::Ridp::PersonToPrimaryRequest.call(
              input_hash.to_json
            ) { |record| @transform_result = record }
            Success(@transform_result)
          end

          # Validate PrimaryRequest params against PrimaryRequest Contract
          def validate_primary_request(params)
            params.merge!({ LevelOfProofingCode: 'LevelThree' })
            result =
              ::AcaEntities::Fdsh::Ridp::H139::PrimaryRequestContract.new.call(params)

            result.success? ? Success(result.to_h) : Failure(result)
          end

          def primary_request_entity(values)
            result = ::AcaEntities::Fdsh::Ridp::H139::PrimaryRequest.new(values.to_h)

            Success(result)
          end
        end
      end
  end
end
