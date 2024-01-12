# frozen_string_literal: true

module Publishers
  module Fdsh
    module Vlp
      # Publish requests to test instance of CMS HTTP FDSH VLP Services
      class CloseCaseRestXmlServicePublisher
        include ::EventSource::Publisher[http: '/CloseCaseServiceV37.1Rest']

        register_event '/CloseCaseServiceV37.1Rest'
      end
    end
  end
end
