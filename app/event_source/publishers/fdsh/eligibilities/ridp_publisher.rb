# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      class RidpPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.eligibilities.ridp']

        register_event 'primary_determination_complete'
        register_event 'secondary_determination_complete'
      end
    end
  end
end
