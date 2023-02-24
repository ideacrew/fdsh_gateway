# frozen_string_literal: true

module Events
  module FdshGateway
    module Tax1095as
      # This class will register event
      class NoticeRequested < EventSource::Event
        publisher_path 'publishers.fdsh_gateway.tax1095as_publisher'

      end
    end
  end
end
