# frozen_string_literal: true

module Publishers
  module Fdsh
    module Pvc
      # The MedicarePublisher class is responsible for publishing events related to Medicare in the Periodic Verification Confirmation (PVC) context.
      # It includes the EventSource::Publisher module to enable event publishing.
      # It registers an event: 'periodic_verification_confirmation_determined'.
      class MedicarePublisher
        include ::EventSource::Publisher[amqp: 'fdsh.pvc.medicare']

        register_event 'periodic_verification_confirmation_determined'
      end
    end
  end
end
