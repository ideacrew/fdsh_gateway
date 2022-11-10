# frozen_string_literal: true

module Fdsh
  module Rrv
    module Medicare
      module Request
        class CreateTransactionFile
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          def call(application_payloads)
            applications         = yield build_applications(application_payloads)
            rrv_medicare_request = yield build_request_entity(applications)
            xml_string           = yield encode_xml_and_schema_validate(rrv_medicare_request)
            rrv_medicare_xml     = yield encode_request_xml(xml_string)
            applicants_count     = rrv_medicare_request.IndividualRequests.count

            Success([rrv_medicare_xml, applicants_count])
          end

          private

          def build_applications(application_payloads)
            applications = application_payloads.collect do |application_hash|
              # try hash with indifferent access?
              result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(application_hash.deep_symbolize_keys)
              result.value! if result.success?
            end.compact

            Success(applications)
          end

          # Transform application params To BuildMedicareRequest Contract params
          def build_request_entity(applications)
            ::AcaEntities::Fdsh::Rrv::Medicare::Operations::BuildMedicareRequest.new.call(applications)
          end

          def encode_xml_and_schema_validate(rrv_medicare_request)
            xml_string = ::AcaEntities::Serializers::Xml::Fdsh::Rrv::Medicare::IndividualRequests.domain_to_mapper(rrv_medicare_request).to_xml

            Success(xml_string)
            # AcaEntities::Serializers::Xml::Fdsh::Rrv::Medicare::Operations::MedicareRequestToXml.new.call(esi_request)
          end

          def encode_request_xml(xml_string)
            encoding_result = Try do
              xml_doc = Nokogiri::XML(xml_string)
              xml_doc.to_xml(:indent => 2, :encoding => 'UTF-8')
            end

            encoding_result.or do |e|
              Failure(e)
            end
          end
        end
      end
    end
  end
end

  