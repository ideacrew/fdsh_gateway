# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      # The HubConnectivityPublisher class is responsible for publishing events related to Hub connectivity.
      # It includes the EventSource::Publisher module to enable event publishing.
      # It registers an event: 'acknowledged'.
      class HubConnectivityPublisher
        include ::EventSource::Publisher[
                  amqp: 'fdsh.eligibilities.hub_connectivity'
                ]

        register_event 'acknowledged'
      end
    end
  end
end
