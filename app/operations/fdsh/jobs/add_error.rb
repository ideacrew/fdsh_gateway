# frozen_string_literal: true

module Fdsh
  module Jobs
    # add an error to a transmittable object.
    class AddError
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        error = yield create_error(values)
        result = yield add_error(values, error)
        Success(result)
      end

      private

      def validate_params(params)
        return Failure('Transmittable objects are not present to update the process status') unless params[:transmittable_objects].is_a?(Hash)
        return Failure('key must be present to update the process status') unless params[:key].is_a?(Symbol)
        return Failure('message must be present to update the process status') unless params[:message].is_a?(String)
        Success(params)
      end

      def add_error(values, error)
        values[:transmittable_objects].each_value do |transmittable_object|
          transmittable_object.transmittable_errors.create(error.to_h)
          transmittable_object.save
        end
        Success("Added error successfully")
      end

      def create_error(values)
        validation_result = AcaEntities::Protocols::Transmittable::Operations::TransmittableErrors::Create.new.call({ key: values[:key],
                                                                                                                      message: values[:message] })

        validation_result.success? ? Success(validation_result.value!) : Failure("Unable to add error due to invalid params")
      end
    end
  end
end