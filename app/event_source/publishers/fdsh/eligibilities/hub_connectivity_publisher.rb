# frozen_string_literal: true

module Publishers::Fdsh::Eligibilities
  class RipdPublisher
    include ::EventSource::Publisher[
              amqp: 'fdsh.eligibilities.hub_connectivity'
            ]

    register_event 'acknowledged'
  end
end
