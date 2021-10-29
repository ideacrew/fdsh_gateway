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
          determination_result = ::Fdsh::Rrv::Medicare::CreateRequestManifestFile.new.call(values[:applications])

          if determination_result.success?
            logger.info("OK: :on_fdsh_rrv_medicare_eligibility_determination_subscriber successful and acked")
            ack(delivery_info.delivery_tag)
          else
            logger.error(
              "Error: :on_fdsh_rrv_medicare_eligibility_determination_subscriber; nacked due to:#{determination_result.inspect}"
            )
            nack(delivery_info.delivery_tag)
          end

        rescue Exception => e
          logger.error(
            "Exception: :on_fdsh_rrv_medicare_eligibility_determination_subscriber\n Exception: #{e.inspect}" +
              "\n Backtrace:\n" + e.backtrace.join("\n")
          )
          nack(delivery_info.delivery_tag)
        end
        # rubocop:enable Lint/RescueException
        # rubocop:enable Style/LineEndConcatenation
        # rubocop:enable Style/StringConcatenation
      end
    end
  end
end
