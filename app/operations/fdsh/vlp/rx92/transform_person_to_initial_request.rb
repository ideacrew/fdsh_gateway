# frozen_string_literal: true

module Fdsh
  module Vlp
    module H92
      # This class takes AcaEntities::People::Person as input and returns the vlp inittial request hash.
      class TransformPersonToInitialRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param params [Hash] The params to execute an FDSH VLP Initial Verification Request
        # @option params [AcaEntities::People::Person] :person
        # @return [Dry::Monads::Result]
        def call(params)
          person = yield validate_person(params)
          request_entity = yield build_request_entity(person)

          Success(request_entity)
        end

        private

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
          # swap this operation when new one available in aca_entities for 37.1
          ::AcaEntities::Fdsh::Vlp::H92::Operations::PersonToInitialRequest.new.call(person)
        end
      end
    end
  end
end
