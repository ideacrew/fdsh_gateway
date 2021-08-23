# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      class NonEsiPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.eligibilities.non_esi']

        register_event 'non_esi_determination_complete'
      end
    end
  end
end
