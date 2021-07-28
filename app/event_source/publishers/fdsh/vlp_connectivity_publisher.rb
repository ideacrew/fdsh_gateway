# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish requests to test instance of CMS HTTP FDSH Vlp Services
    class VlpConnectivityPublisher
      include ::EventSource::Publisher[http: '/HubConnectivityService']

      register_event '/HubConnectivityService'
    end
  end
end
