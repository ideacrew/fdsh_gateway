# frozen_string_literal: true

module Events
  module Fdsh
    # This class will register event
    class OauthConnectivityChecked < EventSource::Event
      publisher_path 'publishers.fdsh.oauth_connectivity_publisher'

    end
  end
end