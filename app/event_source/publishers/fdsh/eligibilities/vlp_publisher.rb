# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      class VlpPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.eligibilities.vlp']

        register_event 'initial_verification_complete'
      end
    end
  end
end
