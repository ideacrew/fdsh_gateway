# frozen_string_literal: true

module Subscribers
  module Fdsh
    module DeterminationRequests
      # Publish events for FDSH RIDP requests
      class RidpDeterminationRequestedSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.determination_requests.ridp']

        subscribe(
          :on_fdsh_determination_requests_ridp_primary_determination_requested
        ) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          # puts "triggered --> on_primary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"
          correlation_id = properties.correlation_id

          determination_result = Fdsh::Ridp::H139::HandlePrimaryDeterminationRequest.new.call({
                                                                                                payload: payload,
                                                                                                correlation_id: correlation_id
                                                                                              })

          if determination_result.success?
            logger.info(
              "OK: :on_fdsh_determination_requests_ridp_primary_determination_requested successful and acked"
            )
            ack(delivery_info.delivery_tag)
          else
            logger.error(
              "Error: :on_fdsh_determination_requests_ridp_primary_determination_requested; nacked due to:#{determination_result.inspect}"
            )
            nack(delivery_info.delivery_tag)
          end
        end

        subscribe(
          :on_fdsh_determination_requests_ridp_secondary_determination_requested
        ) do |_delivery_info, _metadata, payload|
          # Sequence of steps that are executed as single operation
          # puts "triggered --> on_secondary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"

          if Fdsh::Ridp::H139.RequestSecondaryEligibility(payload).success?
            # acknowledge RabbitMQ - will delete message from queue
          end
        end
      end
    end
  end
end
