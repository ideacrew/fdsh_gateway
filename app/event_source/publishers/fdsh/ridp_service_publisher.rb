# frozen_string_literal: true

module Publishers::Fdsh
  # Publish requests to test instance of CMS HTTP FDSH RIDP Services
  class RidpServicePublisher
    include ::EventSource::Publisher[http: '/impl/RIDPService']

    register_event '/impl/RIDPService'
  end
end
