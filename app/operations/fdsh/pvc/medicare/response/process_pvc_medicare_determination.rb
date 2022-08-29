# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'digest'
require 'zip'

module Fdsh
  module Pvc
    module Medicare
      module Response
        # This class processes pvc medicare determination
        class ProcessPvcMedicareDetermination
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          def call(medicare_response)
            determine_individual_response(medicare_response)
            Success(true)
          end

          private

          def determine_individual_response(medicare_response)
            medicare_response.IndividualResponses.each do |individual_response|
              person_ssn = individual_response.PersonSSNIdentification
              next unless person_ssn.present?

              event = event('events.fdsh.pvc_medicaid.individual_response_received',
                            attributes: { payload: individual_response.to_h }).value!

              event.publish
            end
          end
        end
      end
    end
  end
end
