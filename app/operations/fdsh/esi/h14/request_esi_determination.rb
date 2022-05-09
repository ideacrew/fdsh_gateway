# frozen_string_literal: true

module Fdsh
  module Esi
    module H14
      # This class takes a json representing a family as input and invokes RIDP.
      class RequestEsiDetermination
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        PublishEventStruct = Struct.new(:name, :payload, :headers)

        PUBLISH_EVENT = "fdsh_determine_esi_mec_eligibility"

        # @return [Dry::Monads::Result]
        def call(application, params)
          _transaction = yield create_or_update_transaction('application', application.to_h, params)
          esi_request = yield TransformApplicationToEsiMecRequest.new.call(application)
          xml_string = yield encode_xml_and_schema_validate(esi_request)
          _updated_transaction = yield create_or_update_transaction('request', xml_string, params)
          esi_request_xml = yield encode_request_xml(xml_string)

          publish_event(esi_request_xml)
        end

        protected

        def create_or_update_transaction(key, value, params)
          activity_hash = {
            correlation_id: "esi_#{params[:correlation_id]}",
            command: "Fdsh::Esi::H14::RequestEsiDetermination",
            event_key: params[:event_key],
            message: { "#{key}": key == 'request' ? encrypt(value.to_json) : value }
          }

          transaction_hash = {
            correlation_id: activity_hash[:correlation_id],
            activity: activity_hash
          }

          if key == 'application'
            application_string = value.to_json
            application_id = value[:hbx_id]
            primary_hbx_id = value[:applicants].detect {|applicant| applicant[:is_primary_applicant]}&.dig(:person_hbx_id)
            transaction_hash.merge!(magi_medicaid_application: application_string, application_id: application_id, primary_hbx_id: primary_hbx_id)
          end

          Try do
            Journal::Transactions::AddActivity.new.call(transaction_hash)
          end
        end

        def encode_xml_and_schema_validate(esi_request)
          AcaEntities::Serializers::Xml::Fdsh::Esi::H14::Operations::EsiRequestToXml.new.call(esi_request)
        end

        def encrypt(value)
          AcaEntities::Operations::Encryption::Encrypt.new.call({ value: value }).value!
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

          Success(Publishers::Fdsh::EsiServicePublisher.publish(event))
        end

      end
    end
  end
end