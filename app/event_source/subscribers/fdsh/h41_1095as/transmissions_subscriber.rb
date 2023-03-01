# frozen_string_literal: true

module Subscribers
  module Fdsh
    module H411095as
      # Subscribe events for H41 requests
      class TransmissionsSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.h41_1095as']

        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_transmission_requested) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          payload = JSON.parse(payload, :symbolize_names => true)

          result = ::Fdsh::H41::BuildTransmission.new.call(
            deny_list: payload[:deny_list],
            allow_list: payload[:allow_list],
            assistance_year: properties[:headers]['assistance_year'].to_i,
            report_types: properties[:headers]['report_types']
          )

          if result.success?
            logger.info("OK: :on_transmission_requested successful and acked")
          else
            logger.error("Error: :on_transmission_requested; failed due to:#{result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_transmission_requested\n Exception: #{e.inspect}" +
            "\n Backtrace:\n" + e.backtrace.join("\n")
          )
          ack(delivery_info.delivery_tag)
        end
        # rubocop:enable Lint/RescueException
        # rubocop:enable Style/LineEndConcatenation
        # rubocop:enable Style/StringConcatenation
      end
    end
  end
end
