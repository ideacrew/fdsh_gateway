# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from cms requests for esi mec json payload
    class VerifyEsiMecServiceRestSubscriber
      include ::EventSource::Subscriber[http: '/VerifyEsiMecServiceRest']

      subscribe(:on_VerifyESIMECServiceRest) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::VerifyEsiMecServiceRest: on_VerifyEsiMecServiceRest OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::VerifyEsiMecServiceRest: on_VerifyEsiMecServiceRest error #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::VerifyEsiMecServiceRest: on_VerifyEsiMecServiceRest error backtrace: #{e.inspect}, #{e.backtrace}"
      end
    end
  end
end
