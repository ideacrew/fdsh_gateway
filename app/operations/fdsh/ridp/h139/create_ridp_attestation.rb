# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module Ridp
    module H139
      # This class takes happy mapper hash as input and returns
      class CreateRidpAttestation
        include Dry::Monads[:result, :do, :try]
        include AcaEntities::AppHelper

        # @param [Hash] opts The options to process
        # @return [Dry::Monads::Result]
        def call(primary_response)
          params    = yield construct_attestation_params(primary_response)
          values    = yield validate(params)
          entity    = yield create(values)

          Success(entity)
        end

        private

        def construct_attestation_params(response)
          decision_code = response.Response.VerificationResponse&.FinalDecisionCode
          params = {
            is_satisfied: decision_code == 'ACC',
            is_self_attested: true,
            satisfied_at: (decision_code == 'ACC') ? DateTime.now : nil,
            evidences: create_evidence(response),
            status: get_status(decision_code)
          }
          Success(params)
        end

        def get_status(decision_code)
          case decision_code.to_s
          when 'ACC'
            'success'
          when 'REF'
            'failure'
          else
            'in_progress'
          end
        end

        def create_evidence(response)
          input_hash = case response.class.to_s
                       when "AcaEntities::Fdsh::Ridp::H139::PrimaryResponse"
                         { primary_response: response.to_h }
                       when "AcaEntities::Fdsh::Ridp::H139::SecondaryResponse"
                         { secondary_response: response.to_h }
                       end

          [AcaEntities::Evidences::RidpEvidence.new(input_hash).to_h]
        end

        def validate(params)
          result = AcaEntities::Attestations::RidpAttestationContract.new.call(params)

          if result.success?
            Success(result)
          else
            Failure("Invalid response, #{result.errors}")
          end
        end

        def create(value)
          Success(AcaEntities::Attestations::RidpAttestation.new(value.to_h))
        end
      end
    end
  end
end
