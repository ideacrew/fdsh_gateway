# frozen_string_literal: true

module Fdsh
  module Ssa
    module H3
      # This class takes AcaEntities::People::Person as input and returns the SSA Composite Verification request hash.
      class TransformPersonToSsaRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param params [Hash] The params to execute an FDSH SSA Composite Verification Request
        # @option params [AcaEntities::People::Person] :person
        # @return [Dry::Monads::Result]
        def call(params)
          person = yield validate_person(params)
          request_entity = yield build_request_entity(person)

          Success(request_entity)
        end

        # Validate input object
        def validate_person(person)
          if person.is_a?(::AcaEntities::People::Person)
            Success(person)
          else
            Failure(
              "Invalid person, given value is not a ::AcaEntities::People::Person, input_value:#{person}"
            )
          end
        end

        # Transform Person params To PrimaryRequest Contract params
        def build_request_entity(person)
          ::AcaEntities::Fdsh::Ssa::H3::Operations::SsaVerificationRequest.new.call(person)
        end
      end
    end
  end
end
