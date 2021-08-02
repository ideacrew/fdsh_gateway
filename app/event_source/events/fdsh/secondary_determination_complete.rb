# frozen_string_literal: true

module Events
  module Fdsh
    # This class will register event
    class SecondaryDeterminationComplete < EventSource::Event
      publisher_path 'publishers.fdsh.eligibilities.ridp_publisher'

    end
  end
end