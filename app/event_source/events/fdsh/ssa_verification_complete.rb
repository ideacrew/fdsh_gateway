# frozen_string_literal: true

module Events
  module Fdsh
    # This class will register event
    class SsaVerificationComplete < EventSource::Event
      publisher_path 'publishers.fdsh.eligibilities.ssa_publisher'

    end
  end
end