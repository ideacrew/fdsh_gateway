# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from cms requests for ssa json payload
    class VerifySSACompositeServiceRestSubscriber
      include ::EventSource::Subscriber[http: '/VerifySSACompositeServiceRest']

      subscribe(:on_VerifySSACompositeServiceRest) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::SsaServiceSubscribe: on_VerifySSACompositeServiceRest OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::SsaServiceSubscribe: on_VerifySSACompositeServiceRest error #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::SsaServiceSubscribe: on_VerifySSACompositeServiceRest error backtrace: #{e.inspect}, #{e.backtrace}"
      end
    end
  end
end
