# frozen_string_literal: true

module Fdsh
  module Esi
    module H14
      # This class takes AcaEntities::MagiMedicaid::Application as input and returns the Esi Mec request hash.
      class TransformApplicationToEsiMecRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param params [Hash] The params to execute an FDSH SSA Composite Verification Request
        # @option params [AcaEntities::MagiMedicaid::Application] :Applicattion
        # @return [Dry::Monads::Result]
        def call(params)
          application = yield validate_application(params)
          request_entity = yield build_request_entity(application)

          Success(request_entity)
        end

        # Validate input object
        def validate_application(application)
          if application.is_a?(::AcaEntities::MagiMedicaid::Application)
            Success(application)
          else
            Failure(
              "Invalid application, given value is not a ::AcaEntities::MagiMedicaid::Application, input_value:#{application}"
            )
          end
        end

        # Transform application params To EsiMecRequest Contract params
        def build_request_entity(application)
          ::AcaEntities::Fdsh::Esi::H14::Operations::BuildEsiMecRequest.new.call(application)
        end
      end
    end
  end
end
