# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from FDSH requests
    class VlpConnectivitySubscriber
      include ::EventSource::Subscriber[http: '/VlpHubConnectivityService']

      subscribe(:on_VlpHubConnectivityService) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::VlpConnectivitySubscriber: :on_HubConnectivityService OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::VlpConnectivitySubscriber: :on_HubConnectivityService ERROR #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::VlpConnectivitySubscriber: :on_HubConnectivityService ERROR #{e.inspect}"
      end
    end
  end
end
