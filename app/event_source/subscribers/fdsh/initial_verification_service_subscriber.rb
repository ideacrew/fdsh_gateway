# frozen_string_literal: true

module Subscribers
  module Fdsh
    # Receive response from FDSH requests
    class InitialVerificationServiceSubscriber
      include ::EventSource::Subscriber[http: '/VerifyLawfulPresenceServiceV37']

      subscribe(:on_VerifyLawfulPresenceServiceV37) do |body, status, _headers|
        if status.to_s == "200"
          logger.info "Subscribers::Fdsh::Vlp::InitialVerificationServiceSubscribe: on_VLPService OK #{status}, #{body}"
        else
          logger.error "Subscribers::Fdsh::Vlp::InitialVerificationServiceSubscribe: on_VLPService error #{status}, #{body}"
        end
      rescue StandardError => e
        logger.error "Subscribers::Fdsh::Vlp::InitialVerificationServiceSubscribe: on_VLPService error backtrace: #{e.inspect}, #{e.backtrace}"
      end
    end
  end
end
