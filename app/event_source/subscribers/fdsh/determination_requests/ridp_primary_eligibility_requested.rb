# frozen_string_literal: true

module Subscribers
  # Publish events for FDSH RIDP requests
  class RidpElibilityRequestedSubscriber
    include ::EventSource::Subscriber[amqp: 'fdsh.determination_requests.ridp']

    subscribe(
      :on_fdsh_determination_requests_ridp_primary_determination_requested
    ) do |_delivery_info, _metadata, payload|
      # Sequence of steps that are executed as single operation
      # puts "triggered --> on_primary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"

      if Fdsh::Ridp::H139.BuildPrimaryRequest.call(payload).success?
        # acknowledge RabbitMQ - will delete message from queue
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
