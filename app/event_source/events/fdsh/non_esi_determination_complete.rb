# frozen_string_literal: true

module Events
  module Fdsh
    # This class will register event
    class NonEsiDeterminationComplete < EventSource::Event
      publisher_path 'publishers.fdsh.eligibilities.non_esi_publisher'

    end
  end
end