# frozen_string_literal: true

module Subscribers
  module Fdsh
    module InsurancePolicies
      # Subscriber will receive an event(from edi_gateway) 'edi_gateway.insurance_policies.posted'
      class PostedSubscriber
        include ::EventSource::Subscriber[amqp: 'edi_gateway.insurance_policies']

        subscribe(:on_posted) do |delivery_info, metadata, response|
          logger.info "on_posted response: #{response}"
          subscriber_logger = subscriber_logger_for(:on_insurance_policies_posted)
          response = JSON.parse(response, symbolize_names: true)
          logger.info "on_posted response: #{response}"
          subscriber_logger.info "on_posted response: #{response}"
          process_insurance_policies_posted_event(subscriber_logger, response, metadata) unless Rails.env.test?

          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          logger.error "on_posted error: #{e} backtrace: #{e.backtrace}; acked (nacked)"
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

        def process_insurance_policies_posted_event(subscriber_logger, response, headers)
          subscriber_logger.info "process_insurance_policies_posted_event: ------- start"
          result = H41::InsurancePolicies::Enqueue.new.call(
            {
              affected_policies: headers['affected_policies'],
              assistance_year: headers['assistance_year'],
              correlation_id: headers['correlation_id'],
              family: response
            }
          )

          if result.success?
            message = result.success
            subscriber_logger.info "on_posted acked #{message.is_a?(Hash) ? message[:event] : message}"
          else
            subscriber_logger.info "process_insurance_policies_posted_event: failure: #{error_messages(result)}"
          end
          subscriber_logger.info "process_insurance_policies_posted_event: ------- end"
        rescue StandardError => e
          subscriber_logger.error "process_insurance_policies_posted_event: error: #{e} backtrace: #{e.backtrace}"
          subscriber_logger.error "process_insurance_policies_posted_event: ------- end"
        end

        def subscriber_logger_for(event)
          Logger.new("#{Rails.root}/log/#{event}_#{Date.today.in_time_zone('Eastern Time (US & Canada)').strftime('%Y_%m_%d')}.log")
        end
      end
    end
  end
end
