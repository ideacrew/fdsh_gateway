# frozen_string_literal: true

module Subscribers
  module Fdsh
    module DeterminationRequests
      # Publish events for FDSH RRV requests
      class RrvMedicareDeterminationSubscriber
        include ::EventSource::Subscriber[amqp: 'enroll.ivl_market.families.iap_applications.rrvs.non_esi_evidences']

        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_determination_requested) do |delivery_info, _properties, payload|
          # Sequence of steps that are executed as single operation
          values = JSON.parse(payload, :symbolize_names => true)
          determination_result = ::Fdsh::Rrv::Medicare::Request::StoreApplicationRrvRequest.new.call({ application_hash: values[:application] })

          if determination_result.success?
            logger.info("OK: :on_fdsh_rrv_medicare_eligibility_determination_subscriber successful and acked")
          else
            logger.error("Error: :on_fdsh_rrv_medicare_eligibility_determination_subscriber; failed due to:#{determination_result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_fdsh_rrv_medicare_eligibility_determination_subscriber\n Exception: #{e.inspect}" +
              "\n Backtrace:\n" + e.backtrace.join("\n")
          )
          ack(delivery_info.delivery_tag)
        end
        # rubocop:enable Lint/RescueException
        # rubocop:enable Style/LineEndConcatenation
        # rubocop:enable Style/StringConcatenation
      end
    end
  end
end
