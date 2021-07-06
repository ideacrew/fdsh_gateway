# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from FDSH requests
    class RidpConnectivitySubscriber
      include ::EventSource::Subscriber[http: '/HubConnectivityService']

      subscribe(:on_HubConnectivityService) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::RidpConnectivitySubscriber: :on_HubConnectivityService OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::RidpConnectivitySubscriber: :on_HubConnectivityService ERROR #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::RidpConnectivitySubscriber: :on_HubConnectivityService ERROR #{e.inspect}"
      end
    end
  end
end
