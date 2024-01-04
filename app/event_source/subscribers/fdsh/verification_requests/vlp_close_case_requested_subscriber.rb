# frozen_string_literal: true

module Subscribers
  module Fdsh
    module VerificationRequests
      # Publish events for FDSH VLP requests
      class VlpCloseCaseRequestedSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.case_requests.vlp']
        subscribe(:on_close_case_requested) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          # puts "triggered --> on_primary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"
          correlation_id = properties.correlation_id
          case_number = properties.case_number

          verification_result = ::Fdsh::Vlp::Rx142::CloseCase::HandleCloseCaseRequest.new.call({
                                                                                                 payload: payload,
                                                                                                 correlation_id: correlation_id,
                                                                                                 case_number: case_number
                                                                                               })

          if verification_result.success?
            logger.info("OK: :on_close_case_requested successful and acked")
          else
            logger.error("Error: :on_close_case_requested; failed due to:#{verification_result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue StandardError? => e
          logger.error(
            "Exception: :on_close_case_requested\n Exception: #{e.inspect}" \
            "\n Backtrace:\n" + e.backtrace.join("\n")
          )
          ack(delivery_info.delivery_tag)
        end
      end
    end
  end
end