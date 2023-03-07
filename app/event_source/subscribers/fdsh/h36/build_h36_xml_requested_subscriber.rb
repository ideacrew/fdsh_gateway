# frozen_string_literal: true

module Subscribers
  module Fdsh
    module H36
      # Subscribe events for H36 requests
      class BuildH36XmlRequestedSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.h36']

        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_build_xml_requested) do |delivery_info, _properties, payload|
          # Sequence of steps that are executed as single operation
          values = JSON.parse(payload, :symbolize_names => true)
          result = ::Fdsh::H36::Request::BuildH36Xml.new.call(
            { irs_group_id: values[:irs_group_id],
              transmission_id: values[:transmission_id],
              assistance_year: values[:assistance_year],
              month_of_year: values[:month_of_year] }
          )

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
