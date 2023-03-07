# frozen_string_literal: true

module Events
  module Fdsh
    module H36
      # This class will register event
      class BuildH36XmlRequested < EventSource::Event
        publisher_path 'publishers.fdsh.h36.build_h36_xml_requested_publisher'
      end
    end
  end
end