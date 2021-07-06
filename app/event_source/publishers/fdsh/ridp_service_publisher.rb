# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish requests to test instance of CMS HTTP FDSH RIDP Services
    class RidpServicePublisher
      include ::EventSource::Publisher[http: '/RIDPService']

      register_event '/RIDPService'
    end
  end
end
