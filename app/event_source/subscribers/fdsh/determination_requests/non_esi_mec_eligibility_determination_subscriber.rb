# frozen_string_literal: true

module Subscribers
  module Fdsh
    module DeterminationRequests
      # Publish events for FDSH RIDP requests
      class NonEsiMecEligibilityDeterminationSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.determination_requests.non_esi']

        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_determine_non_esi_mec_eligibility) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          correlation_id = properties.correlation_id
          event_key = "determine_non_esi_mec_eligibility"
          non_esi_payload_format = properties[:headers]['non_esi_payload_format']
          determination_result = if non_esi_payload_format == 'json'
                                   ::Fdsh::NonEsi::H31::HandleJsonEligibilityDeterminationRequest.new.call({
                                                                                                             payload: payload,
                                                                                                             correlation_id: correlation_id
                                                                                                           })
                                 else
                                   ::Fdsh::NonEsi::H31::HandleEligibilityDeterminationRequest.new.call({
                                                                                                         payload: payload,
                                                                                                         correlation_id: correlation_id,
                                                                                                         event_key: event_key
                                                                                                       })
                                 end

          if determination_result.success?
            logger.info("OK: :on_fdsh_non_esi_mec_eligibility_determination_subscriber successful and acked")
          else
            logger.error("Error: :on_fdsh_non_esi_mec_eligibility_determination_subscriber; failed due to:#{determination_result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_fdsh_non_esi_mec_eligibility_determination_subscriber\n Exception: #{e.inspect}" +
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
