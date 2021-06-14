# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Ridp
    module H139
      # Transform CV3 to FDSH Requst and call FDSH RIBP Operation
      # Use EventSource HTTP SOAP to perform call
      class SecondaryRequest
        include Dry::Monads[:result, :do]
        include EventSource::Command

        # @param [Hash] params
        # @option params [AcaEntities::Families::Family] family family entity
        # @return [Dry::Monad] result
        def call(params)
          values = yield validate(params)
          fdsh_payload = yield transform(values)
          soap_message = yield build_fdsh_soap_request(fdsh_payload)
          request = yield request_service(soap_message)

          Success(request)
        end

        private
      end
    end
  end
end
