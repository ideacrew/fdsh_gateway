# frozen_string_literal: true

module Events
  module Fdsh
    module RenewalEligibilities
      # This class will register event
      class MagiMedicaidApplicationRenewalEligibilitiesMedicareDetermined < EventSource::Event
        publisher_path 'publishers.fdsh.renewal_eligibilities.medicare_publisher'

      end
    end
  end
end