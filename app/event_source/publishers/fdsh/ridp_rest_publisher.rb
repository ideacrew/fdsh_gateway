# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish RIDP request json payload for response from CMS
    class RidpRestPublisher
      include ::EventSource::Publisher[http: '/RIDPCrossCoreService']

      register_event '/RIDPCrossCoreService'
    end
  end
end
