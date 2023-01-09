# frozen_string_literal: true

module Publishers
  module Fdsh
    module Pvc
      class MedicarePublisher
        include ::EventSource::Publisher[amqp: 'fdsh.pvc.medicare']

        register_event 'periodic_verification_confirmation_determined'
      end
    end
  end
end
