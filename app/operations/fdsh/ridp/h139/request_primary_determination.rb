# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

# High level process flow:
# 1. Enroll will fire event ridp_eligibility_requested with Family sturctured CV3 payload
# 2. FDSH Gateway subsribes to these events: Subscribers::RidpElibilityRequestedSubscriber and
# routes to appropriate operation
# 3. FDSH Gateway subscribes to Subscribers::Fdsh::Ridp::H139 and calls opertion to parse response
# 4. Upon success Publish CV3 response
# 5. Enroll presents questions in form
# 6. Send question reponse to FDSH for secondary call
# 7. How do we handle scenrio where customer obtains RIDP using 800 phone number?

module Fdsh
  module Ridp
    module H139
      # Transform CV3 to FDSH Requst and call FDSH RIBP Operation
      # Use EventSource HTTP SOAP to perform call
      class PrimaryRequest
        include Dry::Monads[:result, :do]
        include EventSource::Command

        # @param [Hash] params
        # @option params [AcaEntities::Families::Family] family family entity
        # @return [Dry::Monad] result
        def call(params)
          #          values = yield validate(params)
          #          fdsh_payload = yield transform(values)
          #          soap_message = yield build_fdsh_soap_request(fdsh_payload)

          # Pattern this after MITC request
          #          request = yield request_service(soap_message)
          #          persist_request = yield persist(request)
          #          event = yield build_event(request)

          #          Success(request)
        end

      end
    end
  end
end
