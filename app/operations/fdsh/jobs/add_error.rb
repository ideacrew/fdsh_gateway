# frozen_string_literal: true

module Fdsh
  module Jobs
    # add an error to a transmittable object.
    class AddError
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        result = yield add_error(values)
        Success(result)
      end

      private

      def validate_params(params)
        return Failure('Transmittable objects are not present to update the process status') unless params[:transmittable_objects].is_a?(Hash)
        return Failure('key must be present to update the process status') unless params[:key].is_a?(Symbol)
        return Failure('message must be present to update the process status') unless params[:message].is_a?(String)
        Success(params)
      end

      def update_status(values)
        values[:transmittable_objects].each_value do |transmittable_object|
          transmittable_object.errors.add(values[:key], :not_implemented, message: values[:message])
        end
        Success("Added error successfully")
      end

    end
  end
end