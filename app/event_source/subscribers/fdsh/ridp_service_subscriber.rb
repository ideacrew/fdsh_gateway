# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from FDSH requests
    class RidpServiceSubscriber
      include ::EventSource::Subscriber[http: '/RIDPService']

      subscribe(:on_RIDPService) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::RidpServiceSubscribe: on_RIDPService OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::RidpServiceSubscribe: on_RIDPService error #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::RidpServiceSubscribe: on_RIDPService error backtrace: #{e.inspect}, #{e.backtrace}"
      end
    end
  end
end
