# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      # The NonEsiPublisher class is responsible for publishing events related to non-ESI (Employer-Sponsored Insurance) eligibilities.
      # It includes the EventSource::Publisher module to enable event publishing.
      # It registers an event: 'non_esi_determination_complete'.
      class NonEsiPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.eligibilities.non_esi']

        register_event 'non_esi_determination_complete'
      end
    end
  end
end
