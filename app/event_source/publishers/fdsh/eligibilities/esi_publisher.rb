# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      class EsiPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.eligibilities.esi']

        register_event 'esi_determination_complete'
      end
    end
  end
end
