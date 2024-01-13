# frozen_string_literal: true

module Subscribers
  module Fdsh
    module Vlp
      # Receive response from cms requests for VLP json payload
      class VerifyVlpCompositeServiceRestSubscriber
        include ::EventSource::Subscriber[http: '/VerifyLawfulPresenceServiceV37.1Rest']

        subscribe(:'on_VerifyLawfulPresenceServiceV37.1Rest') do |body, status, _headers|
          if status.to_s == "200"
            logger.info "Subscribers::Fdsh::VLPServiceSubscribe: on_VerifyVLPServiceRest OK #{status}, #{body}"
          else
            logger.error "Subscribers::Fdsh::VLPServiceSubscribe: on_VerifyVLPServiceRest error #{status}, #{body}"
          end
        rescue StandardError => e
          logger.error "Subscribers::Fdsh::VLPServiceSubscribe: on_VerifyVLPServiceRest error backtrace: #{e.inspect}, #{e.backtrace}"
        end
      end
    end
  end
end