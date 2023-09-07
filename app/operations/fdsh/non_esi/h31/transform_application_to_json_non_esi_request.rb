# frozen_string_literal: true

module Fdsh
  module NonEsi
    module H31
      # This class takes a json representing a application as input and generates non esi json payload.
      class TransformApplicationToJsonNonEsiRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param params [String] the json payload of the application
        # @return [Dry::Monads::Result]
        def call(params)
          json_hash = yield parse_json(params)
          application_entity = yield validate_and_build_application(json_hash)
          person_request_json = yield convert_application_to_request_json(application_entity)

          Success(person_request_json)
        end

        protected

        def parse_json(json_string)
          parsing_result = Try do
            JSON.parse(json_string, :symbolize_names => true)
          end
          parsing_result.or do
            Failure(:invalid_json)
          end
        end

        def validate_and_build_application(json_hash)
          result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(json_hash)
          result.success? ? result : Failure(result.failure.errors.to_h)
        end

        def convert_application_to_request_json(application_entity)
          result = AcaEntities::Fdsh::NonEsi::H31::Operations::NonEsiMecJsonRequest.new.call(application_entity)
          result.success? ? Success(JSON.parse(result.value!, symbolize_names: true)) : Failure("Unable to transform payload to JSON")
        end
      end
    end
  end
end
