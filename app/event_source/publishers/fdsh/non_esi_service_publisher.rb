# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish requests to test instance of CMS HTTP FDSH NON ESI MEC Services
    class NonEsiServicePublisher
      include ::EventSource::Publisher[http: '/VerifyNonEsiMecService']

      register_event '/VerifyNonEsiMecService'
    end
  end
end
