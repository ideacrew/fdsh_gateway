# frozen_string_literal: true

module Subscribers
  module Fdsh
    module H41
      # Subscribe events for H41 requests
      class FamilyRequestSubscriber
        include ::EventSource::Subscriber[amqp: 'edi_gateway.h41.report_items']

        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_created) do |delivery_info, _properties, payload|
          # Sequence of steps that are executed as single operation
          values = JSON.parse(payload, :symbolize_names => true)
          result = ::Fdsh::H41::Request::StoreH41FamilyRequest.new.call({ family_hash: values[:cv3_family] })

          if result.success?
              logger.info("OK: :on_fdsh_irs_request_subscriber successful and acked")
          else
              logger.error("Error: :on_fdsh_irs_request_subscriber; failed due to:#{result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
              "Exception: :on_fdsh_irs_request_subscriber\n Exception: #{e.inspect}" +
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
