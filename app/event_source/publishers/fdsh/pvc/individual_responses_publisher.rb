# frozen_string_literal: true

module Publishers
  module Fdsh
    module Pvc
      # The IndividualResponsesPublisher class is responsible for publishing events
      # related to individual responses in the Periodic Verification Confirmation (PVC) context.
      # It includes the EventSource::Publisher module to enable event publishing.
      # It registers an events: 'individual_response_received'
      class IndividualResponsesPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.pvc.individual_responses']

        register_event 'individual_response_received'
      end
    end
  end
end