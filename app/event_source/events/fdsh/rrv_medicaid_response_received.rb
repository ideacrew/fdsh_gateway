# frozen_string_literal: true

module Events
  module Fdsh
    # This class will register event
    class RrvMedicaidResponseReceived < EventSource::Event
      publisher_path 'publishers.fdsh.eligibilities.rrv_medicaid_response_publisher'

    end
  end
end