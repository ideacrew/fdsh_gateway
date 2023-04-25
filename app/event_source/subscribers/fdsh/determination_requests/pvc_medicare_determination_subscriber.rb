# frozen_string_literal: true

module Subscribers
  module Fdsh
    module DeterminationRequests
      # Publish events for FDSH PVC requests
      class PvcMedicareDeterminationSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.fdsh_verifications.pvc']

        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_periodic_verification_confirmation) do |delivery_info, _properties, payload|
          # Sequence of steps that are executed as single operation
          values = JSON.parse(payload, :symbolize_names => true)
          result = ::Fdsh::Pvc::Medicare::Request::StoreRequest.new.call(application_hash: values[:application])

          if result.success?
            logger.info("OK: :on_periodic_verification_confirmation successful and acked")
          else
            logger.error("Error: :on_periodic_verification_confirmation; failed due to:#{result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_periodic_verification_confirmation\n Exception: #{e.inspect}" +
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