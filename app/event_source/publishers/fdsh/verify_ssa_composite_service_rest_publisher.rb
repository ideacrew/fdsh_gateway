# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish SSA json payload for response from CMS
    class VerifySsaCompositeServiceRestPublisher
      include ::EventSource::Publisher[http: '/VerifySSACompositeServiceRest']

      register_event '/VerifySSACompositeServiceRest'
    end
  end
end
