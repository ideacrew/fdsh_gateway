# frozen_string_literal: true

module Fdsh
  module Jobs
    # Create the failure event and publish it
    class PublishFailureResponse
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      # @param job_id [String] job id for matching jobs cross app
      # @param event_name [String] which event should be triggered
      # @param correlation_id [String] correlation_id for matching with subject
      # @return [Dry::Monads::Result]
      def call(params)
        values = yield validate_params(params)
        event = yield build_event(values)
        publish_event(event)
      end

      private

      def validate_params(params)
        return Failure('needs job_id for matching jobs in EA') unless params[:job_id].is_a?(String)
        return Failure('needs event name to trigger proper event') unless params[:event_name].is_a?(String)
        return Failure('needs correlation_id for matching in EA') unless params[:correlation_id].is_a?(String)
        Success(params)
      end

      def build_event(params)
        event(params[:event_name], headers: { correlation_id: params[:correlation_id], job_id: params[:job_id], status: "failure" })
      end

      def publish_event(event)
        Try() { event.publish }.to_result
      end
    end
  end
end
