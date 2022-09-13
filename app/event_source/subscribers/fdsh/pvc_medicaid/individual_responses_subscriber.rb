# frozen_string_literal: true

module Subscribers
  module Fdsh
    module PvcMedicaid
      # Publish events for FDSH SSA requests
      class IndividualResponsesSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.pvc.individual_responses']
        # rubocop:disable Lint/RescueException
        subscribe(:on_fdsh_pvc_individual_responses) do |delivery_info, _properties, payload|
          values = JSON.parse(payload, :symbolize_names => true)
          result = ::Fdsh::Pvc::Medicare::Response::ProcessIndividualPvcResponse.new.call(values[:payload])

          if result.success?
            logger.info("OK: :on_fdsh_pvc_individual_responsess successful and acked")
          else
            logger.error("Error: :on_fdsh_pvc_individual_responsess; failed due to:#{result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error("Exception: :on_fdsh_pvc_individual_responsess\n Exception: #{e.inspect}\n Backtrace:\n #{e.backtrace.join("\n")}")
          ack(delivery_info.delivery_tag)
        end
        # rubocop:enable Lint/RescueException
      end
    end
  end
end
