# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from json RIDP requests
    class RidpRestSubscriber
      include ::EventSource::Subscriber[http: '/RIDPCrossCoreService']

      subscribe(:on_RIDPCrossCoreService) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::RidpRestSubscriber: on_RIDPCrossCoreService OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::RidpRestSubscriber: on_RIDPCrossCoreService error #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::RidpRestSubscriber: on_RIDPCrossCoreService error backtrace: #{e.inspect}, #{e.backtrace}"
      end
    end
  end
end
