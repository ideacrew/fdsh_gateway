# frozen_string_literal: true

module Publishers::Fdsh::Eligibilities
  class RipdPublisher
    include ::EventSource::Publisher[amqp: 'fdsh.eligibilities.ridp']

    # Sends AcaEntities::Attestations::Attestation payload
    register_event 'determined_primary_eligible'
    register_event 'determined_primary_ineligible'

    register_event 'determined_secondary_eligible'
    register_event 'determined_secondary_ineligible'
  end
end
