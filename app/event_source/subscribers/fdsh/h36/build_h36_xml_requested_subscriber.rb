# frozen_string_literal: true

module Subscribers
  module Fdsh
    module H36
      # Subscribe events for H36 requests
      class BuildH36XmlRequestedSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.h36']

        subscribe(:on_build_xml_requested) do |delivery_info, _properties, payload|
          subscriber_logger = subscriber_logger_for(:on_build_xml_requested)
          values = JSON.parse(payload, :symbolize_names => true)

          process_build_h36_xml_request(subscriber_logger, values)
          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          logger.error "on_build_xml_requested error: #{e} backtrace: #{e.backtrace}; acked (nacked)"
          ack(delivery_info.delivery_tag)
        end

        private

        def error_messages(result)
          if result.failure.is_a?(Dry::Validation::Result)
            result.failure.errors.to_h
          else
            result.failure
          end
        end

        def process_build_h36_xml_request(subscriber_logger, values)
          subscriber_logger.info "process_h36_transmission_requested_event: ------- start"
          result = ::Fdsh::H36::Request::BuildH36Xml.new.call(
            { irs_group_id: values[:irs_group_id],
              transmission_id: values[:transmission_id],
              assistance_year: values[:assistance_year],
              month_of_year: values[:month_of_year] }
          )

          if result.success?
            message = result.success
            subscriber_logger.info "on_build_xml_requested acked #{message.is_a?(Hash) ? message[:event] : message}"
          else
            subscriber_logger.info "process_build_h36_xml_request: failure: #{error_messages(result)}"
          end
          subscriber_logger.info "process_build_h36_xml_request: ------- end"
        rescue StandardError => e
          subscriber_logger.error "process_build_h36_xml_request: error: #{e} backtrace: #{e.backtrace}"
          subscriber_logger.error "process_build_h36_xml_request: ------- end"
        end

        def subscriber_logger_for(event)
          Logger.new("#{Rails.root}/log/#{event}_#{Date.today.in_time_zone('Eastern Time (US & Canada)').strftime('%Y_%m_%d')}.log")
        end
      end
    end
  end
end
