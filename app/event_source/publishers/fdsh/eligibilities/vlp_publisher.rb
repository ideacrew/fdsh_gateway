# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      # The VlpPublisher class is responsible for publishing events related to VLP (Verification of Lawful Presence) eligibilities.
      # It includes the EventSource::Publisher module to enable event publishing.
      # It registers an event: 'initial_verification_complete'.
      class VlpPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.eligibilities.vlp']

        register_event 'initial_verification_complete'
      end
    end
  end
end
