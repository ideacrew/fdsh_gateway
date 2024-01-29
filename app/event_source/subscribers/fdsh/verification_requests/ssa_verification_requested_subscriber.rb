# frozen_string_literal: true

module Subscribers
  module Fdsh
    module VerificationRequests
      # Publish events for FDSH SSA requests
      class SsaVerificationRequestedSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.verification_requests.ssa']
        subscribe(:on_ssa_verification_requested) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          # puts "triggered --> on_primary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"
          correlation_id = properties.correlation_id
          payload_type = properties[:headers]["payload_type"]
          job_id = properties[:headers]["job_id"]
          verification_result = if payload_type == 'json'
                                  ::Fdsh::Ssa::H3::HandleJsonSsaVerificationRequest.new.call({
                                                                                               correlation_id: correlation_id,
                                                                                               job_id: job_id,
                                                                                               payload: payload
                                                                                             })
                                else
                                  ::Fdsh::Ssa::H3::HandleXmlSsaVerificationRequest.new.call({
                                                                                              payload: payload,
                                                                                              correlation_id: correlation_id
                                                                                            })

                                end
          if verification_result.success?
            logger.info("OK: :on_fdsh_verification_requests_ssa_verification_requested successful and acked")
          else
            publish_failure(job_id)
            logger.error("Error: :on_fdsh_verification_requests_ssa_verification_requested; failed due to:#{verification_result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue StandardError => e
          publish_failure(job_id)
          logger.error(
            "Exception: :on_fdsh_verification_requests_ssa_verification_requested\n Exception: #{e.inspect}" \
            "\n Backtrace:\n" + e.backtrace.join("\n")
          )
          ack(delivery_info.delivery_tag)
        end

        def publish_failure(job_id)
          event('events.fdsh.ssa_verification_complete', headers: { job_id: job_id, status: "failure" })
          event.publish
        end
      end
    end
  end
end
