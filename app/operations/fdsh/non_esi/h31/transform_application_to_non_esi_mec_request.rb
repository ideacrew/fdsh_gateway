# frozen_string_literal: true

module Fdsh
  module NonEsi
    module H31
      # This class takes AcaEntities::MagiMedicaid::Application as input and returns the Esi Mec request hash.
      class TransformApplicationToNonEsiMecRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param params [Hash] The params to execute an FDSH SSA Composite Verification Request
        # @option params [AcaEntities::MagiMedicaid::Application] :Applicattion
        # @return [Dry::Monads::Result]
        def call(application)
          valid_application = yield validate_application(application)
          request_entity = yield build_request_entity(valid_application)

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
          ::AcaEntities::Fdsh::NonEsi::H31::Operations::BuildNonEsiMecRequest.new.call(application)
        end
      end
    end
  end
end
