# frozen_string_literal: true

module Publishers
  module Fdsh
    module RenewalEligibilities
      # The MedicarePublisher class is responsible for publishing events related to Medicare renewal eligibilities.
      # It includes the EventSource::Publisher module to enable event publishing.
      # It registers an event: 'magi_medicaid_application_renewal_eligibilities_medicare_determined'.
      class MedicarePublisher
        include ::EventSource::Publisher[amqp: 'fdsh.renewal_eligibilities.medicare']

        register_event 'magi_medicaid_application_renewal_eligibilities_medicare_determined'
      end
    end
  end
end
