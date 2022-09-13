# frozen_string_literal: true

module Events
    module Fdsh
      module Pvc
        # This class will register event
        class IndividualResponseReceived < EventSource::Event
          publisher_path 'publishers.fdsh.pvc.individual_responses_publisher'
  
        end
      end
    end
  end