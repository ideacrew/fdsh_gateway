# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish Esi json payload for response from CMS
    class VerifyEsiMecServiceRestPublisher
      include ::EventSource::Publisher[http: '/VerifyEsiMecServiceRest']

      register_event '/VerifyEsiMecServiceRest'
    end
  end
end
