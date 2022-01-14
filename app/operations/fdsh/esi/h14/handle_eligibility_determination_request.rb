# frozen_string_literal: true

module Fdsh
  module Esi
    module H14
      # Invoke a Eligibility Determination service, and, if appropriate, broadcast the response.
      class HandleEligibilityDeterminationRequest
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @return [Dry::Monads::Result]
        def call(params)
          application = yield parse_and_build_application(params[:payload])
          esi_determination_result_soap = yield RequestEsiDetermination.new.call(application, params)
          esi_determination_result = yield ::Soap::RemoveSoapEnvelope.new.call(esi_determination_result_soap.body)
          esi_mec_response = yield ProcessEsiDeterminationResponse.new.call(esi_determination_result, params)
          modified_application = yield UpdateApplicationWithResponse.new.call(application, esi_mec_response, params[:correlation_id])
          event  = yield build_event(params[:correlation_id], modified_application)
          result = yield publish(event)

          Success(result)
        end

        protected

        def parse_and_build_application(json_string)
          parsing_result = Try do
            JSON.parse(json_string, :symbolize_names => true)
          end

          if parsing_result.success?
            result = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(parsing_result.value!)
            result.success? ? result : Failure(result.failure.errors.to_h)
          else
            Failure(:invalid_json)
          end
        end

        def build_event(correlation_id, modified_application)
          payload = modified_application.to_h

          event('events.fdsh.esi_determination_complete', attributes: payload, headers: { correlation_id: correlation_id })
        end

        def publish(event)
          event.publish

          Success('ESI determination response published successfully')
        end
      end
    end
  end
end