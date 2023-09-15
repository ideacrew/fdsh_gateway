# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from cms requests for esi mec json payload
    class VerifyEsiMecServiceRestSubscriber
      include ::EventSource::Subscriber[http: '/VerifyESIMECServiceRest']

      subscribe(:on_VerifyESIMECServiceRest) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::VerifyESIMECServiceRest: on_VerifyESIMECServiceRest OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::VerifyESIMECServiceRest: on_VerifyESIMECServiceRest error #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::VerifyESIMECServiceRest: on_VerifyESIMECServiceRest error backtrace: #{e.inspect}, #{e.backtrace}"
      end
    end
  end
end
