# frozen_string_literal: true

module Fdsh
  module Jobs
    # Update the process status of a transmittable object
    class UpdateProcessStatus
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        result = yield update_status(values)
        Success(result)
      end

      private

      def validate_params(params)
        return Failure('Transmittable objects are not present to update the process status') unless params[:transmittable_objects].is_a?(Hash)
        return Failure('State must be present to update the process status') unless params[:state].is_a?(Symbol)
        return Failure('message must be present to update the process status') unless params[:message].is_a?(String)
        Success(params)
      end

      def update_status(values)
        values[:transmittable_objects].each do |_key, transmittable_object|
          transmittable_object.process_status.latest_state = values[:state]
          last_process_state = transmittable_object&.process_status&.process_states&.last
          last_process_state.ended_at = DateTime.now if last_process_state
          transmittable_object.process_status.process_states.create({ event: values[:state].to_s,
                                                                      message: values[:message],
                                                                      started_at: DateTime.now,
                                                                      state_key: values[:state] })
          transmittable_object.process_status.save
          if [:failed, :completed, :succeeded].include?(values[:state])
            transmittable_object.ended_at = DateTime.now
            last_process_state = transmittable_object&.process_status&.process_states&.last
            if last_process_state
              last_process_state.ended_at = DateTime.now
              last_process_state.save
            end
          end
          transmittable_object.save
        end
        Success("Process status updated successfully")
      rescue StandardError => e
        Fdsh::Jobs::AddError.new.call({ transmittable_objects: transmittable_objects, key: :update_process_status,
                                        message: "Error updating process status: #{e.message}" })
        Failure("Error updating process status: #{e.message}")
      end
    end
  end
end
