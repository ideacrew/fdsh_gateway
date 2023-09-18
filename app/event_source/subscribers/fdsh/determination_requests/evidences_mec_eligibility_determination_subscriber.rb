# frozen_string_literal: true

module Subscribers
  module Fdsh
    module DeterminationRequests
      # Publish events for FDSH RIDP requests
      class EvidencesMecEligibilityDeterminationSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.evidences']

        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_esi_determination_requested) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          correlation_id = properties.correlation_id
          esi_payload_format = properties[:headers]['esi_mec_payload_format']
          esi_result = if esi_payload_format == 'json'
                         ::Fdsh::Esi::Rj14::HandleJsonEligibilityDeterminationRequest.new.call({
                                                                                                 payload: payload,
                                                                                                 correlation_id: correlation_id
                                                                                               })
                       else
                         ::Fdsh::Esi::H14::HandleEligibilityDeterminationRequest.new.call({
                                                                                            payload: payload,
                                                                                            correlation_id: correlation_id,
                                                                                            event_key: 'determine_esi_mec_eligibility'
                                                                                          })
                       end

          if esi_result.success?
            logger.info("OK: :on_esi_determination_requested successful and acked")
          else
            logger.error("Error: :on_esi_determination_requested; failed for application id #{correlation_id} due to:#{esi_result.inspect}")
          end

          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_evidences_mec_eligibility_determination_subscriber failed for application id #{correlation_id}\n" +
            "Exception: #{e.inspect}" +
            "\n Backtrace:\n" + e.backtrace.join("\n")
          )
          ack(delivery_info.delivery_tag)
        end

        subscribe(:on_non_esi_determination_requested) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          correlation_id = properties.correlation_id
          non_esi_payload_format = properties[:headers]['non_esi_payload_format']
          non_esi_result = if non_esi_payload_format == 'json'
                             ::Fdsh::NonEsi::Rj31::HandleJsonEligibilityDeterminationRequest.new.call({
                                                                                                        payload: payload,
                                                                                                        correlation_id: correlation_id
                                                                                                      })
                           else
                             ::Fdsh::NonEsi::H31::HandleEligibilityDeterminationRequest.new.call({
                                                                                                   payload: payload,
                                                                                                   correlation_id: correlation_id,
                                                                                                   event_key: 'determine_non_esi_mec_eligibility'
                                                                                                 })
                           end
          if non_esi_result.success?
            logger.info("OK: :on_non_esi_determination_requested successful and acked")
          else
            logger.error("Error: :on_non_esi_determination_requested; failed for application id #{correlation_id} due to:#{non_esi_result.inspect}")
          end

          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_evidences_mec_eligibility_determination_subscriber failed for application id #{correlation_id} \n" +
            "Exception: #{e.inspect} \n" +
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
