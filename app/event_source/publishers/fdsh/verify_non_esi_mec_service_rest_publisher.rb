# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish SSA json payload for response from CMS
    class VerifyNonEsiMecServiceRestPublisher
      include ::EventSource::Publisher[http: '/VerifyNonEsiMecServiceRest']

      register_event '/VerifyNonEsiMecServiceRest'
    end
  end
end
