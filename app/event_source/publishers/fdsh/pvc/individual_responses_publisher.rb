# frozen_string_literal: true

module Publishers
    module Fdsh
      module Pvc
        class IndividualResponsesPublisher
          include ::EventSource::Publisher[amqp: 'fdsh.pvc.individual_responses']
  
          register_event 'individual_response_received'
        end
      end
    end
  end
  