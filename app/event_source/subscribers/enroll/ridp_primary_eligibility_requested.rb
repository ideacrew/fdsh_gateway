# frozen_string_literal: true

module Subscribers
  # Publish events for FDSH RIDP requests
  class RidpElibilityRequestedSubscriber
    include ::EventSource::Publisher[amqp: 'fdsh.ridp.requests']

    subscribe(:on_primary_request) do |delivery_info, metadata, payload|
      # Sequence of steps that are executed as single operation
      # puts "triggered --> on_primary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"

      if Fdsh::Ridp::H139.RequestPrimaryEligibility(payload).success?
        # acknowledge RabbitMQ - will delete message from queue
      else

      end
    end

    subscribe(:on_secondary_request) do |delivery_info, metadata, payload|
      # Sequence of steps that are executed as single operation
      # puts "triggered --> on_secondary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"

      if Fdsh::Ridp::H139.RequestSecondaryEligibility(payload).success?
        # acknowledge RabbitMQ - will delete message from queue
      else

      end
    end
  end
end
