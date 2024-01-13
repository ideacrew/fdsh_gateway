# frozen_string_literal: true

module Publishers
  module Fdsh
    module Vlp
      # Publish VLP json payload for response from CMS
      class VerifyVlpServiceRestPublisher
        include ::EventSource::Publisher[http: '/VerifyLawfulPresenceServiceV37.1Rest']

        register_event '/VerifyLawfulPresenceServiceV37.1Rest'
      end
    end
  end
end