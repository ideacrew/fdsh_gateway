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
          payload_type = properties[:headers]["payload_type"]

          verification_result = if payload_type == "rest_xml"
                                  ::Fdsh::Vlp::Rx142::InitialVerification::HandleInitialVerificationRequest
                                    .new.call({ payload: payload, correlation_id: correlation_id })
                                else
                                  ::Fdsh::Vlp::H92::HandleInitialVerificationRequest
                                    .new.call({ payload: payload, correlation_id: correlation_id })
                                end

          if verification_result.success?
            logger.info("OK: :on_fdsh_verification_requests_vlp_initial_verification_requested successful and acked")
          else
            logger.error("Error: :on_fdsh_verification_requests_vlp_initial_verification_requested; failed due to:#{verification_result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_fdsh_verification_requests_vlp_initial_verification_requested\n Exception: #{e.inspect}" +
            "request properties: #{properties}" +
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
