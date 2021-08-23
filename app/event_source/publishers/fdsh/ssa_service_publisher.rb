# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish requests to test instance of CMS HTTP FDSH SSA Services
    class SsaServicePublisher
      include ::EventSource::Publisher[http: '/VerifySSACompositeService']

      register_event '/VerifySSACompositeService'
    end
  end
end
