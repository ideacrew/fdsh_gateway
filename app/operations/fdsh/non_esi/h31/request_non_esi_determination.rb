# frozen_string_literal: true

module Fdsh
  module NonEsi
    module H31
      # This class takes a json representing a family as input and invokes RIDP.
      class RequestNonEsiDetermination
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        PublishEventStruct = Struct.new(:name, :payload, :headers)

        PUBLISH_EVENT = "fdsh_determine_non_esi_mec_eligibility"

        # @return [Dry::Monads::Result]
        def call(application, params)
          _transaction = yield create_or_update_transaction('application', application.to_h, params)
          non_esi_request = yield TransformApplicationToNonEsiMecRequest.new.call(application)
          xml_string = yield encode_xml_and_schema_validate(non_esi_request)
          _updated_transaction = yield create_or_update_transaction('request', xml_string, params)
          non_esi_request_xml = yield encode_request_xml(xml_string)

          publish_event(non_esi_request_xml)
        end

        protected

        def create_or_update_transaction(key, value, params)
          activity_hash = {
            correlation_id: "non_esi_#{params[:correlation_id]}",
            command: "Fdsh::NonEsi::H31::RequestNonEsiDetermination",
            event_key: params[:event_key],
            message: { "#{key}": value }
          }

          Try do
            Journal::Transactions::AddActivity.new.call(activity_hash)
          end
        end

        def encode_xml_and_schema_validate(non_esi_request)
          AcaEntities::Serializers::Xml::Fdsh::NonEsi::H31::Operations::NonEsiRequestToXml.new.call(non_esi_request)
        end

        def encode_request_xml(xml_string)
          encoding_result = Try do
            xml_doc = Nokogiri::XML(xml_string)
            xml_doc.to_xml(:indent => 2, :encoding => 'UTF-8', :save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
          end

          encoding_result.or do |e|
            Failure(e)
          end
        end

        def publish_event(esi_request_xml)
          event = PublishEventStruct.new(PUBLISH_EVENT, esi_request_xml)

          Success(Publishers::Fdsh::NonEsiServicePublisher.publish(event))
        end

      end
    end
  end
end