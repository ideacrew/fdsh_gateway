# frozen_string_literal: true

module Publishers
  module Fdsh
    module Ridp
      module H139
        module Publishers
          # Publish events for FDSH RIDP requests
          class RidpEligibilitiesPublisher
            include ::EventSource::Publisher[http: 'fdsh/RIDPService']

            register_event 'primary_request_determined'
            register_event 'secondary_request_determined'
          end
        end
      end
    end
  end
end
