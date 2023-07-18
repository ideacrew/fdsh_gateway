# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive connectivity response from Oauth FDSH requests
    class OauthConnectivitySubscriber
      include ::EventSource::Subscriber[http: '/HubConnectivityServiceRest']

      subscribe(:on_HubConnectivityServiceRest) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::OauthConnectivitySubscriber: :on_HubConnectivityServiceRest OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::OauthConnectivitySubscriber: :on_HubConnectivityServiceRest ERROR #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::OauthConnectivitySubscriber: :on_HubConnectivityServiceRest ERROR #{e.inspect}"
      end
    end
  end
end
