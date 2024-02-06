# frozen_string_literal: true

module Publishers
  module Fdsh
    module Eligibilities
      # The RidpPublisher class is responsible for publishing events related to RIDP (Referral, Identity Proofing) eligibilities.
      # It includes the EventSource::Publisher module to enable event publishing.
      # It registers an event: 'ridp_verification_complete'.
      class RidpPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.eligibilities.ridp']

        register_event 'primary_determination_complete'
        register_event 'secondary_determination_complete'
      end
    end
  end
end
