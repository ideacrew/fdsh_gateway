# frozen_string_literal: true

module Publishers
  module Fdsh
    module RenewalEligibilities
      class MedicarePublisher
        include ::EventSource::Publisher[amqp: 'fdsh.renewal_eligibilities.medicare']

        register_event 'magi_medicaid_application_renewal_eligibilities_medicare_determined'
      end
    end
  end
end
