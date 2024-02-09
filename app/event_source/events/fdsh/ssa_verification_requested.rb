# frozen_string_literal: true

module Events
  module Fdsh
    # This class will register event
    class SsaVerificationRequested < EventSource::Event
      publisher_path 'publishers.fdsh.verify_ssa_composite_service_rest_publisher'

    end
  end
end