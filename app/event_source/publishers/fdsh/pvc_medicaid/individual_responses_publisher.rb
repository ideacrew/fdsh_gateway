# frozen_string_literal: true

module Publishers
  module Fdsh
    module PvcMedicaid
      class IndividualResponsesPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.pvc_medicaid.individual_responses']

        register_event 'individual_response_received'
      end
    end
  end
end
