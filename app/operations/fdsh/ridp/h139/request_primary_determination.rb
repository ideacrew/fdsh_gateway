# frozen_string_literal: true

module Fdsh
  module Ridp
    module H139
      # This class takes a json representing a family as input and invokes RIDP.
      class RequestPrimaryDetermination
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param params [String] the json payload of the family
        # @return [Dry::Monads::Result]
        def call(params)
          json_hash = yield parse_json(params)
          family_hash = yield validate_family(json_hash)
          family = yield build_family(family_hash)
          determination_request = yield TransformFamilyToPrimaryDetermination.new.call(params)
          determination_request_xml = yield encode_request_xml(determination_request)

          publish_event(determination_request_xml)
        end

        protected

        def parse_json(json_string)
          Try do
            JSON.parse(json_string)
          end.or do
            Failure(:invalid_json)
          end
        end

        def encode_request_xml(determination_request)
          Try do
            AcaEntities::Serializers::Xml::Fdsh::Ridp::PrimaryRequest.domain_to_mapper(
              determination_request
            ).to_xml
          end.or do |e|
            Failure(e)
          end
        end

        def validate_family_json_hash(json_hash)
          validation_result = AcaEntities::Contract::Families::Family.new.call(json_hash)

          validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
        end

        def build_family(family_hash)
          Try do
            AcaEntities::Families::Family.new(family_hash)
          end.or do |e|
            Failure(e)
          end
        end
=begin
        def publish_event(_request_json)
          event =
            event 'organizations.general_organization_created',
                  attributes: organization.to_h
          event.publish
          logger.info "Published event: #{event}"
        end
=end
      end
    end
  end
end