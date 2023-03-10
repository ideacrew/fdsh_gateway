# frozen_string_literal: true

module Subscribers
  module SystemDate
    # System date changed subscriber
    class ChangedSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.system_date']

      subscribe(:on_changed) do |delivery_info, metadata, _response|
        subscriber_logger = subscriber_logger_for(:on_system_date_changed)
        process_date_change_event(subscriber_logger, metadata[:headers]['system_date'].to_date)
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        logger.error "on_create_requested error: #{e} backtrace: #{e.backtrace}; acked (nacked)"
        ack(delivery_info.delivery_tag)
      end

      private

      def process_date_change_event(subscriber_logger, system_date)
        subscriber_logger.info "system_date: #{system_date}"

        return if system_date != Date.today.beginning_of_month

        year = system_date.year
        month = system_date.month
        result = ::Fdsh::H36::IrsGroups::UpdateH36Transactions.new.call({ assistance_year: year,
                                                                          month_of_year: month })
        if result.success?
          message = result.success
          subscriber_logger.info "on_system_date_changed H36 Cloning acked #{message.is_a?(Hash) ? message[:event] : message}"
        else
          subscriber_logger.info "on_system_date_changed H36 Cloning: failure: #{error_messages(result)}"
        end
        subscriber_logger.info "on_system_date_changed H36 Transmission create: ------- end"
      rescue StandardError => e
        subscriber_logger.error "on_system_date_changed H36 Transmission create: error: #{e} backtrace: #{e.backtrace}"
        subscriber_logger.error "on_system_date_changed H36 Transmission create: ------- end"
      end

      def subscriber_logger_for(event)
        Logger.new("#{Rails.root}/log/#{event}_#{Date.today.in_time_zone('Eastern Time (US & Canada)').strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
