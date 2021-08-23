# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      class SsaPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.eligibilities.ssa']

        register_event 'ssa_verification_complete'
      end
    end
  end
end
