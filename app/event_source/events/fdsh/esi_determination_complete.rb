# frozen_string_literal: true

module Events
  module Fdsh
    # This class will register event
    class EsiDeterminationComplete < EventSource::Event
      publisher_path 'publishers.fdsh.eligibilities.esi_publisher'

    end
  end
end