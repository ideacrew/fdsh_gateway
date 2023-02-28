# frozen_string_literal: true

module Events
  module FdshGateway
    module Irs1095as
      # This class will register event
      class InitialNoticeRequested < EventSource::Event
        publisher_path 'publishers.fdsh_gateway.irs1095as_publisher'

      end
    end
  end
end
