# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publish RIDP primary request json payload for response from CMS
    class RidpPrimaryRequestRestPublisher
      include ::EventSource::Publisher[http: '/RIDPCrossCoreService']

      register_event '/RIDPCrossCoreService'
    end
  end
end
