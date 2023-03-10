# frozen_string_literal: true

module Subscribers
  module Fdsh
    module H36
      # Subscribe events for H36 requests from enroll
      class TransmissionsSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.h36']

        subscribe(:on_transmission_requested) do |delivery_info, _properties, _payload|
          payload = JSON.parse(payload, symbolize_names: true)
          result = ::Fdsh::H36::Transmissions::BuildTransmission.new.call(
            deny_list: payload[:deny_list],
            allow_list: payload[:allow_list],
            assistance_year: properties[:headers]['assistance_year'].to_i,
            month_of_year: properties[:headers]['month_of_year'].to_i
          )

          if result.success?
            logger.info("OK: :on_transmission_requested successful and acked")
          else
            logger.error("Error: :on_transmission_requested; failed due to:#{result.inspect}")
          end

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          logger.error("Exception: :on_transmission_requested Exception: #{e.inspect} Backtrace: #{e.backtrace.join('\n')}")
          ack(delivery_info.delivery_tag)
        end

      end
    end
  end
end
