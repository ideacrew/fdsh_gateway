# frozen_string_literal: true

module Fdsh
  module Rrv
    module Medicare
      # This class takes AcaEntities::MagiMedicaid::Application as input and returns the Esi Mec request hash.
      class TransformApplicationToRrvMedicareRequest
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

        # Transform application params To BuildMedicareRequest Contract params
        def build_request_entity(application)
          ::AcaEntities::Fdsh::Rrv::Medicare::Operations::BuildMedicareRequest.new.call(application)
        end
      end
    end
  end
end
