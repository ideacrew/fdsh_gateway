# frozen_string_literal: true

module Publishers
  module Fdsh
    module RrvMedicaid
      # The IndividualResponsesPublisher class is responsible for publishing events related to individual responses in the RRV Medicaid context.
      # It includes the EventSource::Publisher module to enable event publishing.
      # It registers an event: 'individual_response_received'
      class IndividualResponsesPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.rrv_medicaid.individual_responses']

        register_event 'individual_response_received'
      end
    end
  end
end
