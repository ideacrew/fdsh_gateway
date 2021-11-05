# frozen_string_literal: true

module Subscribers
  module Fdsh
    module VerificationRequests
      # Publish events for FDSH VLP requests
      class VlpVerificationRequestedSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.verification_requests.vlp']
        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_initial_verification_requested) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          # puts "triggered --> on_primary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"
          correlation_id = properties.correlation_id

          verification_result = ::Fdsh::Vlp::H92::HandleInitialVerificationRequest.new.call({
                                                                                              payload: payload,
                                                                                              correlation_id: correlation_id
                                                                                            })

          if verification_result.success?
            logger.info("OK: :on_fdsh_verification_requests_vlp_initial_verification_requested successful and acked")
          else
            logger.error("Error: :on_fdsh_verification_requests_vlp_initial_verification_requested; failed due to:#{verification_result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_fdsh_verification_requests_vlp_initial_verification_requested\n Exception: #{e.inspect}" +
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
