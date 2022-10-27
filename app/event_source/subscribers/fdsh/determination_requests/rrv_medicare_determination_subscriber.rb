# frozen_string_literal: true

module Subscribers
  module Fdsh
    module DeterminationRequests
      # Publish events for FDSH RRV requests
      class RrvMedicareDeterminationSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.fdsh_verifications.rrv']

        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_magi_medicaid_application_renewal_assistance_eligible) do |delivery_info, _properties, payload|
          # Sequence of steps that are executed as single operation
          values = JSON.parse(payload, :symbolize_names => true)

          subscriber_logger.info "Processing #{values[:applications].count} applications"
          determination_result = ::Fdsh::Rrv::Medicare::CreateRequestManifestFile.new.call(values[:applications])
          subscriber_logger.info "Processed #{values[:applications].count} applications with result #{determination_result}"

          if determination_result.success?
            subscriber_logger.info "OK: :on_fdsh_rrv_medicare_eligibility_determination_subscriber successful and acked"
            logger.info("OK: :on_fdsh_rrv_medicare_eligibility_determination_subscriber successful and acked")
          else
            subscriber_logger.info "Error: :on_fdsh_rrv_medicare_eligibility_determination_subscriber; failed due to:#{determination_result.inspect}"
            logger.error("Error: :on_fdsh_rrv_medicare_eligibility_determination_subscriber; failed due to:#{determination_result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          subscriber_logger.info(
            "Exception: :on_fdsh_rrv_medicare_eligibility_determination_subscriber\n Exception: #{e.inspect}" +
              "\n Backtrace:\n" + e.backtrace.join("\n")
          )
          logger.error(
            "Exception: :on_fdsh_rrv_medicare_eligibility_determination_subscriber\n Exception: #{e.inspect}" +
              "\n Backtrace:\n" + e.backtrace.join("\n")
          )
          ack(delivery_info.delivery_tag)
        end
        # rubocop:enable Lint/RescueException
        # rubocop:enable Style/LineEndConcatenation
        # rubocop:enable Style/StringConcatenation

        private

        def subscriber_logger
          return @subscriber_logger if defined? @subscriber_logger
          @subscriber_logger = Logger.new(
            "#{Rails.root}/log/on_magi_medicaid_application_renewal_assistance_eligible_events_#{Time.now.strftime('%Y_%m_%d')}.log"
          )
        end
      end
    end
  end
end
