# frozen_string_literal: true

module Publishers
  module Fdsh
    module H36
      # Publish requests build h36 xml
      class BuildH36XmlRequestedPublisher
        include ::EventSource::Publisher[amqp: 'fdsh.h36']

        register_event 'build_xml_requested'
      end
    end
  end
end
