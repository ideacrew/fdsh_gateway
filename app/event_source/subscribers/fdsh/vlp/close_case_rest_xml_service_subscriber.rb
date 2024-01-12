# frozen_string_literal: true

module Subscribers
  module Fdsh
    module Vlp
      # Receive response from FDSH requests
      class CloseCaseRestXmlServiceSubscriber
        include ::EventSource::Subscriber[http: '/CloseCaseServiceV37.1Rest']

        subscribe(:on_CloseCaseServiceV37Rest) do |body, status, _headers|
          if status.to_s == "200"
            logger.info "Subscribers::Fdsh::Vlp::CloseCaseServiceSubscribe: on_VLPCloseCaseService OK #{status}, #{body}"
          else
            logger.error "Subscribers::Fdsh::Vlp::CloseCaseServiceSubscribe: on_VLPCloseCaseService error #{status}, #{body}"
          end
        rescue StandardError => e
          logger.error "Subscribers::Fdsh::Vlp::CloseCaseServiceSubscribe: on_VLPCloseCaseService error backtrace: #{e.inspect}, #{e.backtrace}"
        end
      end
    end
  end
end