# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish requests to test instance of CMS HTTP FDSH Oauth Services
    class OauthConnectivityPublisher
      include ::EventSource::Publisher[http: '/HubConnectivityServiceRest']

      register_event '/HubConnectivityServiceRest'
    end
  end
end