# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from FDSH requests
    class EsiServiceSubscriber
      include ::EventSource::Subscriber[http: '/CalculateOPMPremiumServiceV2']

      subscribe(:on_CalculateOPMPremiumServiceV2) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::EsiServiceSubscribe: on_CalculateOPMPremiumServiceV2 OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::EsiServiceSubscribe: on_CalculateOPMPremiumServiceV2 error #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::EsiServiceSubscribe: on_CalculateOPMPremiumServiceV2 error backtrace: #{e.inspect}, #{e.backtrace}"
      end
    end
  end
end
