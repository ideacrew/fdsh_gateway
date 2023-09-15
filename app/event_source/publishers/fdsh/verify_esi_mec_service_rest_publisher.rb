# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish Esi json payload for response from CMS
    class VerifyEsiMecServiceRestPublisher
      include ::EventSource::Publisher[http: '/VerifyESIMECServiceRest']

      register_event '/VerifyESIMECServiceRest'
    end
  end
end
