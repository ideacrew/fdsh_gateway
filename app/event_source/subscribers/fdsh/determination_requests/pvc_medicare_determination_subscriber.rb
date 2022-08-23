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
        subscribe(:tbd_pvc_event) do |delivery_info, _properties, payload|
          # on_periodic_verification_confirmation <- possible new event name
          # Sequence of steps that are executed as single operation
          values = JSON.parse(payload, :symbolize_names => true)
          determination_result = ::Fdsh::Pvc::Medicare::Request::CreateRequestManifestFile.new.call(values[:applications])

          if determination_result.success?
            logger.info("OK: :tbd_pvc_event successful and acked")
          else
            logger.error("Error: :tbd_pvc_event; failed due to:#{determination_result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :tbd_pvc_event\n Exception: #{e.inspect}" +
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
