# frozen_string_literal: true

module Subscribers
  module Fdsh
    module RrvMedicaid
      # Publish events for FDSH SSA requests
      class IndividualResponsesSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.rrv_medicaid.individual_responses']
        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(:on_fdsh_rrv_medicaid_individual_responses) do |delivery_info, _properties, payload|
          values = JSON.parse(payload, :symbolize_names => true)
          result = ::Fdsh::Rrv::Medicare::Response::ProcessIndividualRrvResponse.new.call(values[:payload])

          if result.success?
            logger.info("OK: :on_fdsh_rrv_medicaid_responses successful and acked")
          else
            logger.error("Error: :on_fdsh_rrv_medicaid_responses; failed due to:#{result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_fdsh_rrv_medicaid_responses\n Exception: #{e.inspect}" +
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
