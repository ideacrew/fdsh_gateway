# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish requests to test instance of CMS HTTP FDSH Vlp Services
    class VlpConnectivityPublisher
      include ::EventSource::Publisher[http: '/VlpHubConnectivityService']

      register_event '/VlpHubConnectivityService'
    end
  end
end
