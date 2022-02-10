# frozen_string_literal: true

module Publishers
    module Fdsh
      module Eligibilities
        class RrvMedicaidResponsePublisher
          include ::EventSource::Publisher[amqp: 'fdsh.rrv_medicaid.responses']
  
          register_event 'response_received'
        end
      end
    end
end