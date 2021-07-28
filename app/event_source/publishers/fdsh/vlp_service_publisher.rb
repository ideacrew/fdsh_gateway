# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish requests to test instance of CMS HTTP FDSH VLP Services
    class VlpServicePublisher
      include ::EventSource::Publisher[http: '/VerifyLawfulPresenceServiceV37']

      register_event '/VerifyLawfulPresenceServiceV37'
    end
  end
end
