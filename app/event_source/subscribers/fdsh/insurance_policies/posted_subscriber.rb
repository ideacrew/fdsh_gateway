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
          subscriber_logger.info "JSON payload #{response}"
          response = JSON.parse(response, symbolize_names: true)
          logger.info "on_posted response: #{response}"
          subscriber_logger.info "on_posted response: #{response} with headers #{metadata}"

          unless Rails.env.test?
            process_insurance_policies_posted_event_for_h41(subscriber_logger, response, metadata)

            process_insurance_policies_posted_event_for_h36(subscriber_logger, response, metadata)
          end

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

        # rubocop:disable Metrics/MethodLength
        def process_insurance_policies_posted_event_for_h36(subscriber_logger, response, metadata)
          subscriber_logger.info "process_h36_insurance_policies_posted_event: ------- start"
          month = if metadata[:headers]['assistance_year'].to_i == Date.today.year - 1
                    12 + Date.today.month
                  elsif metadata[:headers]['assistance_year'].to_i == Date.today.year + 1
                    1
                  elsif metadata[:headers]['assistance_year'].to_i == Date.today.year
                    Date.today.month
                  end

          enqueue = ::Fdsh::H36::IrsGroups::Enqueue.new.call(
            {
              assistance_year: metadata[:headers]['assistance_year'].to_i,
              correlation_id: metadata[:correlation_id],
              month_of_year: month,
              family: response[:family]
            }
          )

          if enqueue.success?
            message = enqueue.success
            subscriber_logger.info "on_h36_insurance_policies_posted acked #{message.is_a?(Hash) ? message[:event] : message}"
          else
            failure = error_messages(enqueue)
            subscriber_logger.info "process_h36_insurance_policies_posted_event: failure: #{failure}"
          end
          subscriber_logger.info "process_h36_insurance_policies_posted_event: ------- end"
        rescue StandardError => e
          subscriber_logger.error "process_h36_insurance_policies_posted_event: error: #{e} backtrace: #{e.backtrace}"
          subscriber_logger.error "process_h36_insurance_policies_posted_event: ------- end"
        end
        # rubocop:enable Metrics/MethodLength

        def process_insurance_policies_posted_event_for_h41(subscriber_logger, response, metadata)
          subscriber_logger.info "process_insurance_policies_posted_event: ------- start"
          result = ::Fdsh::H41::InsurancePolicies::Enqueue.new.call(
            {
              affected_policies: metadata[:headers]['affected_policies'],
              assistance_year: metadata[:headers]['assistance_year'],
              correlation_id: metadata[:correlation_id],
              family: response[:family]
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
