# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish requests to test instance of CMS HTTP FDSH ESI MEC Services
    class EsiServicePublisher
      include ::EventSource::Publisher[http: '/CalculateOPMPremiumServiceV2']

      register_event '/CalculateOPMPremiumServiceV2'
    end
  end
end
