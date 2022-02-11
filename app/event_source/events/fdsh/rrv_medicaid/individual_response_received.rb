# frozen_string_literal: true

module Events
  module Fdsh
    module RrvMedicaid
      # This class will register event
      class IndividualResponseReceived < EventSource::Event
        publisher_path 'publishers.fdsh.rrv_medicaid.individual_responses_publisher'

      end
    end
  end
end