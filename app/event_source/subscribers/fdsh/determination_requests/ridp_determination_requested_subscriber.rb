# frozen_string_literal: true

module Subscribers
  module Fdsh
    module DeterminationRequests
      # Publish events for FDSH RIDP requests
      class RidpDeterminationRequestedSubscriber
        include ::EventSource::Subscriber[amqp: 'fdsh.determination_requests.ridp']
        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/LineEndConcatenation
        # rubocop:disable Style/StringConcatenation
        subscribe(
          :on_primary_determination_requested
        ) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          # puts "triggered --> on_primary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"
          correlation_id = properties.correlation_id

          determination_result = ::Fdsh::Ridp::H139::HandlePrimaryDeterminationRequest.new.call({
                                                                                                  payload: payload,
                                                                                                  correlation_id: correlation_id
                                                                                                })

          if determination_result.success?
            logger.info("OK: :on_fdsh_determination_requests_ridp_primary_determination_requested successful and acked")
          else
            logger.error("Error: :on_fdsh_determination_requests_ridp_primary_determination_requested; due to:#{determination_result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_fdsh_determination_requests_ridp_primary_determination_requested\n Exception: #{e.inspect}" +
            "\n Backtrace:\n" + e.backtrace.join("\n")
          )
          ack(delivery_info.delivery_tag)
        end

        subscribe(
          :on_secondary_determination_requested
        ) do |delivery_info, properties, payload|
          # Sequence of steps that are executed as single operation
          # puts "triggered --> on_secondary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"
          # Sequence of steps that are executed as single operation
          # puts "triggered --> on_primary_request block -- #{delivery_info} --  #{metadata} -- #{payload}"
          correlation_id = properties.correlation_id

          determination_result = ::Fdsh::Ridp::H139::HandleSecondaryDeterminationRequest.new.call({
                                                                                                    payload: payload,
                                                                                                    correlation_id: correlation_id
                                                                                                  })

          if determination_result.success?
            logger.info("OK: :on_fdsh_determination_requests_ridp_secondary_determination_requested successful and acked")
          else
            logger.error("Error: :on_fdsh_determination_requests_ridp_secondary_determination_requested; due to:#{determination_result.inspect}")
          end
          ack(delivery_info.delivery_tag)
        rescue Exception => e
          logger.error(
            "Exception: :on_fdsh_determination_requests_ridp_secondary_determination_requested\n Exception: #{e.inspect}" +
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
