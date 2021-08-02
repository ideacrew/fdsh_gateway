# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      class HubConnectivityPublisher
        include ::EventSource::Publisher[
                  amqp: 'fdsh.eligibilities.hub_connectivity'
                ]

        register_event 'acknowledged'
      end
    end
  end
end
