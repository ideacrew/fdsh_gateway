# frozen_string_literal: true

module Subscribers
  module Fdsh
    module Ridp
      module H139
        # Publish events for FDSH RIDP requests
        class PrimaryElibilityRepsonseSubscriber
          include ::EventSource::Publisher[http: 'fdsh/RIDPService']
          # include ::EventSource::Publisher[http: '/<fdsh ridp endpoint>']

          subscribe(
            :'on/<ridp primary endpont>'
          ) do |delivery_info, metadata, payload|
            # Sequence of steps that are executed as single operation
            puts "triggered --> on_primary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"

            # call Operation that parses FDSH SOAP response
          end
        end
      end
    end
  end
end
