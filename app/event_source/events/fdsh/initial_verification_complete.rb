# frozen_string_literal: true

module Events
  module Fdsh
    # This class will register event
    class InitialVerificationComplete < EventSource::Event
      publisher_path 'publishers.fdsh.eligibilities.vlp_publisher'

    end
  end
end