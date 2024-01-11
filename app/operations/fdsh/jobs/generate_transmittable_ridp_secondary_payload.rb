# frozen_string_literal: true

module Fdsh
  module Jobs
    # create ridp secondary determination payload that takes params of key (required), started_at(required), publish_on(required), payload (required)
    class GenerateTransmittableRidpSecondaryPayload
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        _job = yield find_job(values)
        _ids = yield validate_ids(params)
        @transmission = yield create_transmission(values)
        person_subject = yield find_person_subject(values)
        @transaction = yield create_transaction(values, person_subject)
        @transaction = yield generate_transmittable_payload(values[:payload], values[:transmission_id])
        transmittable
      end

      private

      def validate_params(params)
        return Failure('Transmittable payload cannot be created without a key as a symbol') unless params[:key].is_a?(Symbol)
        return Failure('Transmittable payload cannot be created without a started_at as a Datetime') unless params[:started_at].is_a?(DateTime)
        return Failure('Transmittable payload cannot be created without a publish_on as a Datetime') unless params[:publish_on].is_a?(DateTime)
        return Failure('Transmittable payload cannot be created without a payload') unless params[:payload]
        Success(params)
      end

      def find_job(values)
        @job = Transmittable::Job.where(title: "RIDP Primary Request for #{values[:session_id]}")&.last
        return Success(@job) if @job

        result = Fdsh::Jobs::FindOrCreateJob.new.call(values)

        if result.success?
          @job = result.value!
          @job.generate_message_id
          Success(@job)
        else
          result
        end
      end

      def validate_ids(params)
        return Success(params) if params[:correlation_id].is_a?(String) && params[:transmission_id].is_a?(String)
        unless params[:correlation_id].is_a?(String)
          add_errors({ job: @job }, "Failed to create secondary request without a correlation_id",
                     :validate_ids)
        end
        unless params[:transmission_id].is_a?(String)
          add_errors({ job: @job }, "Failed to create secondary request without a transmission_id",
                     :validate_ids)
        end
        failure_message = 'Transmittable payload cannot be created without a transmission_id and correlation_id'
        status_result = update_status({ job: @job }, :failed, failure_message)
        return status_result if status_result.failure?
        Failure(failure_message)
      end

      def create_transmission(values)
        result = Fdsh::Jobs::CreateTransmission.new.call(values.merge({ job: @job, event: 'secondary initial', state_key: :initial }))

        return result if result.success?
        add_errors({ job: @job }, "Failed to create transmission due to #{result.failure}", :create_request_transmission)
        status_result = update_status({ job: @job }, :failed, result.failure)
        return status_result if status_result.failure?
        result
      end

      def add_errors(transmittable_objects, message, error_key)
        Fdsh::Jobs::AddError.new.call({ transmittable_objects: transmittable_objects, key: error_key, message: message })
      end

      def update_status(transmittable_objects, state, message)
        Fdsh::Jobs::UpdateProcessStatus.new.call({ transmittable_objects: transmittable_objects, state: state, message: message })
      end

      def find_person_subject(values)
        existing_person = ::Transmittable::Person.where(hbx_id: values[:correlation_id])&.last
        return Success(existing_person) if existing_person
        add_errors({ job: @job, transmission: @transmission }, "Unable to find existing person subject",
                   :find_ridp_primary_subject)
        status_result = update_status({ job: @job, transmission: @transmission }, :failed, "Unable to find existing person subject")
        return status_result if status_result.failure?
        Failure("Unable to find existing person subject")
      end

      def create_transaction(values, subject)
        result = Fdsh::Jobs::CreateTransaction.new.call(values.merge({ transmission: @transmission,
                                                                       subject: subject,
                                                                       event: 'initial',
                                                                       state_key: :initial }))
        return result if result.success?
        add_errors({ job: @job, transmission: @transmission }, "Failed to create transaction due to #{result.failure}", :create_transaction)
        status_result = update_status({ job: @job, transmission: @transmission }, :failed, result.failure)
        return status_result if status_result.failure?
        result
      end

      def generate_transmittable_payload(payload, transmission_id)
        result = Fdsh::Ridp::Rj139::TransformFamilyToSecondaryRequest.new.call(payload, transmission_id)
        if result.success?
          @transaction.json_payload = JSON.parse(result.value!) if result.success?
          @transaction.save

          return Success(@transaction) if @transaction.json_payload
          add_errors({ job: @job, transmission: @transmission, transaction: @transaction },
                     "Unable to save transaction with payload",
                     :generate_transmittable_payload)
          status_result = update_status({ job: @job, transmission: @transmission, transaction: @transaction }, :failed,
                                        "Unable to save transaction with payload")
          status_result if status_result.failure?
        else
          add_errors({ job: @job, transmission: @transmission, transaction: @transaction },
                     "Unable to transform payload due to #{result.failure}",
                     :generate_transmittable_payload)
          status_result = update_status({ job: @job, transmission: @transmission, transaction: @transaction }, :failed, "Unable to transform payload")
          return status_result if status_result.failure?
          result
        end
      end

      def transmittable
        message_id = @job.message_id

        if @transaction.json_payload && message_id
          Success({ transaction: @transaction,
                    message_id: message_id })
        else
          add_errors({ job: @job, transmission: @transmission, transaction: @transaction },
                     "Transaction do not consists of a payload or no message id found",
                     :transmittable)
          status_result = update_status({ job: @job, transmission: @transmission, transaction: @transaction }, :failed,
                                        "Transaction do not consists of a payload or no message id found")
          return status_result if status_result.failure?
          Failure("Transaction do not consists of a payload or no message id found")
        end
      end
    end
  end
end
