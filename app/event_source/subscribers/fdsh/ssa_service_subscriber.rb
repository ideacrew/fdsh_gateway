# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from FDSH requests
    class SsaServiceSubscriber
      include ::EventSource::Subscriber[http: '/VerifySSACompositeService']

      subscribe(:on_VerifySSACompositeService) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::SsaServiceSubscribe: on_VerifySSACompositeService OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::SsaServiceSubscribe: on_VerifySSACompositeService error #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::SsaServiceSubscribe: on_VerifySSACompositeService error backtrace: #{e.inspect}, #{e.backtrace}"
      end
    end
  end
end
