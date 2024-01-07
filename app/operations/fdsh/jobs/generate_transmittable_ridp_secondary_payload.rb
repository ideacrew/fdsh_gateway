# frozen_string_literal: true

module Fdsh
  module Jobs
    # create ridp secondary determination payload that takes params of key (required), started_at(required), publish_on(required), payload (required)
    class GenerateTransmittableRidpSecondaryPayload
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        payload = yield generate_transmittable_payload(values[:payload]) # this should be the last second step
        _job = yield find_job(values) # change this to find_or_create_job
        @transmission = yield create_transmission(values)
        person_subject = yield create_person_subject(values)
        @transaction = yield create_transaction(values, person_subject, payload)

        transmittable
      end

      private

      def validate_params(params)
        return Failure('Transmittable payload cannot be created without a key as a symbol') unless params[:key].is_a?(Symbol)
        return Failure('Transmittable payload cannot be created without a started_at as a Datetime') unless params[:started_at].is_a?(DateTime)
        return Failure('Transmittable payload cannot be created without a publish_on as a Datetime') unless params[:publish_on].is_a?(DateTime)
        return Failure('Transmittable payload cannot be created without a payload') unless params[:payload]
        return Failure('Transmittable payload cannot be created without a correlation_id a string') unless params[:correlation_id].is_a?(String)

        Success(params)
      end

      def generate_transmittable_payload(payload)
        # there is a missing call within this operation to an aca_entities operation that will need to be added!
        Fdsh::Ridp::Rj139::TransformFamilyToSecondaryRequest.new.call(payload)
      end

      def find_job(values)
        # if there is no job we need to create one
        # parsed_payload = JSON.parse(payload, deep_symbolize_keys)
        # session_id = parsed_payload[:secondaryRequest][:sessionIdentification]
        return Failure("No session_id found") unless values[:session_id]
        # need to adjust this to check for job status as well
        @job = Transmittable::Job.where(title: "RIDP Primary Request for #{values[:session_id]}")
        @job ? Success(@job) : Failure("No existing job present")
      end

      def create_transmission(values)
        # need to adjust these values
        result = Fdsh::Jobs::CreateTransmission.new.call(values.merge({ job: @job, event: 'initial', state_key: :initial }))

        return result if result.success?
        add_errors({ job: @job }, "Failed to create transmission due to #{result.failure}", :create_request_transmission)
        status_result = update_status({ job: @job }, :failed, result.failure)
        return status_result if status_result.failure?
      end

      def add_errors(transmittable_objects, message, error_key)
        Fdsh::Jobs::AddError.new.call({ transmittable_objects: transmittable_objects, key: error_key, message: message })
      end

      def update_status(transmittable_objects, state, message)
        Fdsh::Jobs::UpdateProcessStatus.new.call({ transmittable_objects: transmittable_objects, state: state, message: message })
      end

      def create_person_subject(values)
        if @existing_person
          Success(@existing_person)
        else
          person_hash = JSON.parse(values[:payload], symbolize_names: true)

          person = ::Transmittable::Person.create(hbx_id: person_hash[:hbx_id],
                                                  correlation_id: values[:correlation_id],
                                                  encrypted_ssn: person_hash[:person_demographics][:encrypted_ssn],
                                                  surname: person_hash[:person_name][:last_name],
                                                  given_name: person_hash[:person_name][:first_name],
                                                  middle_name: person_hash[:person_name][:middle_name],
                                                  dob: person_hash[:person_demographics][:dob])

          return Success(person) if person.persisted?
          add_errors({ job: @job, transmission: @transmission }, "Unable to save person subject due to #{person.errors&.full_messages}",
                     :create_ridp_primary_subject)
          status_result = update_status({ job: @job, transmission: @transmission }, :failed, "Unable to save person subject")
          return status_result if status_result.failure?
          Failure("Unable to save person subject")
        end
      end

      def create_transaction(values, subject, payload)
        result = Fdsh::Jobs::CreateTransaction.new.call(values.merge({ transmission: @transmission,
                                                                       subject: subject,
                                                                       event: 'initial',
                                                                       state_key: :initial,
                                                                       json_payload: payload }))
        return result if result.success?
        add_errors({ job: @job, transmission: @transmission }, "Failed to create transaction due to #{result.failure}", :create_transaction)
        status_result = update_status({ job: @job, transmission: @transmission }, :failed, result.failure)
        return status_result if status_result.failure?
        result
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
