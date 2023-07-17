# frozen_string_literal: true

module Fdsh
  module Ssa
    module H3
      # This class takes a json representing a person as input and generates ssa json payload.
      class TransformPersonToJsonSsa
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param params [String] the json payload of the person
        # @return [Dry::Monads::Result]
        def call(params)
          json_hash = yield parse_json(params)
          person_hash = yield validate_person_json_hash(json_hash)
          person = yield build_person(person_hash)
          person_request_json = yield convert_person_to_request_json(person)

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

        def validate_person_json_hash(json_hash)
          validation_result = AcaEntities::Contracts::People::PersonContract.new.call(json_hash)

          validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
        end

        def build_person(person_hash)
          creation_result = Try do
            AcaEntities::People::Person.new(person_hash)
          end

          creation_result.or do |e|
            Failure(e)
          end
        end

        def convert_person_to_request_json(person)
          result = AcaEntities::Fdsh::Ssa::H3::Operations::SsaVerificationJsonRequest.new.call(person)

          result.success? ? Success(JSON.parse(result.value!, symbolize_names: true)) : Failure("Unable to transform payload to JSON")
        end
      end
    end
  end
end