# frozen_string_literal: true

module Events
  module Fdsh
    module Pvc
      # This class will register event
      class PeriodicVerificationConfirmationDetermined < EventSource::Event
        publisher_path 'publishers.fdsh.pvc.medicare_publisher'

      end
    end
  end
end