# frozen_string_literal: true

module Subscribers
  module Fdsh
    module DeterminationRequests
      # Publish events for FDSH RIDP requests
      class MecEligibilityDeterminationSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.fdsh.verifications']

        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_magi_medicaid_application_determined) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          correlation_id = properties.correlation_id
          esi_result = ::Fdsh::Esi::H14::HandleEligibilityDeterminationRequest.new.call({
                                                                                          payload: payload,
                                                                                          correlation_id: correlation_id,
                                                                                          event_key: 'determine_esi_mec_eligibility'
                                                                                        })

          if esi_result.success?
            logger.info("OK: :on_fdsh_mec_eligibility_determination_subscriber successful and acked")
          else
            logger.error("Error: :on_fdsh_mec_eligibility_determination_subscriber; failed for application id #{correlation_id} due to:#{esi_result.inspect}")
          end

          non_esi_result = ::Fdsh::NonEsi::H31::HandleEligibilityDeterminationRequest.new.call({
                                                                                                 payload: payload,
                                                                                                 correlation_id: correlation_id,
                                                                                                 event_key: 'determine_non_esi_mec_eligibility'
                                                                                               })

          if non_esi_result.success?
            logger.info("OK: :on_fdsh_mec_eligibility_determination_subscriber successful and acked")
          else
            logger.error("Error: :on_fdsh_mec_eligibility_determination_subscriber; failed for application id #{correlation_id} due to:#{non_esi_result.inspect}")
          end

          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_fdsh_mec_eligibility_determination_subscriber failed for application id #{correlation_id} \n" +
            "Exception: #{e.inspect}" +
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
