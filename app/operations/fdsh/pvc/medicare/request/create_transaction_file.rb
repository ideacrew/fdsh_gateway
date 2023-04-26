# frozen_string_literal: true

module Fdsh
  module Pvc
    module Medicare
      module Request
        # This class takes an application payload hash as input and returns transaction xml and applicant count.
        class CreateTransactionFile
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          def call(params)
            values               = yield validate(params)
            application          = yield build_application(values)
            esi_payload          = yield construct_request_payload(application, values[:assistance_year])
            pvc_medicare_request = yield build_request_entity(esi_payload)
            xml_string           = yield encode_xml_and_schema_validate(pvc_medicare_request)
            pvc_medicare_xml     = yield encode_request_xml(xml_string)
            applicants_count     = pvc_medicare_request.IndividualRequests.count

            Success([pvc_medicare_xml, applicants_count])
          end

          private

          def validate(params)
            errors = []
            errors << 'application payload is missing' unless params[:application_payload]
            errors << 'assistance year is missing' unless params[:assistance_year]

            errors.present? ? Failure(errors) : Success(params)
          end

          def build_application(values)
            result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(values[:application_payload].deep_symbolize_keys)

            result.success? ? result : Failure(result.failure.errors.to_h)
          end

          def can_skip_applicant?(applicant)
            applicant.identifying_information.encrypted_ssn.blank? || applicant.non_esi_evidence.blank?
          end

          def construct_request_payload(application, assistance_year)
            applicant_requests = application.applicants.collect do |applicant|
              can_skip_applicant?(applicant)
              ::AcaEntities::Fdsh::Pvc::Medicare::Operations::BuildMedicareRequest.new.call(applicant, assistance_year).value!
            end.compact

            payload = { IndividualRequests: applicant_requests }

            result = AcaEntities::Fdsh::Rrv::Medicare::EesDshBatchRequestDataContract.new.call(payload)
            result.success? ? Success(result) : Failure("Invalid Non ESI request due to #{result.errors.to_h}")
          end

          def build_request_entity(payload)
            Success(AcaEntities::Fdsh::Rrv::Medicare::EesDshBatchRequestData.new(payload.to_h))
          end

          def encode_xml_and_schema_validate(pvc_medicare_request)
            xml_string = ::AcaEntities::Serializers::Xml::Fdsh::Pvc::Medicare::IndividualRequests.domain_to_mapper(pvc_medicare_request).to_xml

            Success(xml_string)
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
