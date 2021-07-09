# frozen_string_literal: true

module Fdsh
  module Ridp
    module H139
      # This class takes a json representing a family as input and invokes RIDP.
      class RequestPrimaryDetermination
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        PublishEventStruct = Struct.new(:name, :payload, :headers)

        PUBLISH_EVENT = "fdsh_primary_determination_requested"

        # @param params [String] the json payload of the family
        # @return [Dry::Monads::Result]
        def call(params)
          json_hash = yield parse_json(params)
          family_hash = yield validate_family_json_hash(json_hash)
          family = yield build_family(family_hash)
          determination_request = yield TransformFamilyToPrimaryDetermination.new.call(family)
          determination_request_xml = yield encode_request_xml(determination_request)

          publish_event(determination_request_xml)
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

        def encode_request_xml(determination_request)
          encoding_result = Try do
            AcaEntities::Serializers::Xml::Fdsh::Ridp::PrimaryRequest.domain_to_mapper(
              determination_request
            ).to_xml
          end

          encoding_result.or do |e|
            Failure(e)
          end
        end

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

        # Re-enable once soap is fixed.
        def publish_event(determination_request_xml)
          event = PublishEventStruct.new(PUBLISH_EVENT, determination_request_xml)

          Success(Publishers::Fdsh::RidpServicePublisher.publish(event))
        end

      end
    end
  end
end