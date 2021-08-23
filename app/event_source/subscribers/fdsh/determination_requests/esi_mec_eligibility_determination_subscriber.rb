# frozen_string_literal: true

module Subscribers
  module Fdsh
    module DeterminationRequests
      # Publish events for FDSH RIDP requests
      class EsiMecEligibilityDeterminationSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.determination_requests.esi']

        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_determine_esi_mec_eligibility) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          correlation_id = properties.correlation_id
          event_key = "determine_esi_mec_eligibility"

          determination_result = ::Fdsh::Esi::H14::HandleEligibilityDeterminationRequest.new.call({
                                                                                                    payload: payload,
                                                                                                    correlation_id: correlation_id,
                                                                                                    event_key: event_key
                                                                                                  })

          if determination_result.success?
            logger.info(
              "OK: :on_fdsh_esi_mec_eligibility_determination_subscriber successful and acked"
            )
            ack(delivery_info.delivery_tag)
          else
            logger.error(
              "Error: :on_fdsh_esi_mec_eligibility_determination_subscriber; nacked due to:#{determination_result.inspect}"
            )
            nack(delivery_info.delivery_tag)
          end

        rescue Exception => e
          logger.error(
            "Exception: :on_fdsh_esi_mec_eligibility_determination_subscriber\n Exception: #{e.inspect}" +
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
