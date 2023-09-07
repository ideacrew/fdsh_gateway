# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from cms requests for non esi mec json payload
    class VerifyNonEsiMecServiceRestSubscriber
      include ::EventSource::Subscriber[http: '/VerifyNonEsiMecServiceRest']

      subscribe(:on_VerifySSACompositeServiceRest) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::NonEsiMecServiceSubscribe: on_VerifyNonEsiMecServiceRest OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::NonEsiMecServiceSubscribe: on_VerifyNonEsiMecServiceRest error #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::NonEsiMecServiceSubscribe: on_VerifyNonEsiMecServiceRest error backtrace: #{e.inspect}, #{e.backtrace}"
      end
    end
  end
end
