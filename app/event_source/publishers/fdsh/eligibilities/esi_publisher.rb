# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      # The EsiPublisher class is responsible for publishing events related to ESI (Employer-Sponsored Insurance) eligibilities.
      # It includes the EventSource::Publisher module to enable event publishing.
      # It registers an event: 'esi_determination_complete'.
      class EsiPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.eligibilities.esi']

        register_event 'esi_determination_complete'
      end
    end
  end
end
