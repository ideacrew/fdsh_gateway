# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      # The SsaPublisher class is responsible for publishing events related to SSA (Social Security Administration) eligibilities.
      # It includes the EventSource::Publisher module to enable event publishing.
      # It registers an event: 'ssa_verification_complete'.
      class SsaPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.eligibilities.ssa']

        register_event 'ssa_verification_complete'
      end
    end
  end
end
