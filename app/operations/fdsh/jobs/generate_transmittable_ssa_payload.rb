# frozen_string_literal: true

module Fdsh
  module Jobs
    # create job operation that takes params of key (required), started_at(required), publish_on(required), payload (required)
    class GenerateTransmittableSsaPayload
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate_params(params)
        _job = yield create_job(values)
        @transmission = yield create_transmission(values)
        person_subject = yield create_person_subject(values)
        @transaction = yield create_transaction(values, person_subject)
        @transaction = yield generate_transmittable_payload(values[:payload])

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

      def create_job(values)
        result = Fdsh::Jobs::FindOrCreateJob.new.call(values)

        if result.success?
          @job = result.value!
          @job.generate_message_id
          Success(@job)
        else
          result
        end
      end

      def create_transmission(values)
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
        existing_ssa_person = ::Ssa::Person.where(correlation_id: values[:correlation_id]).first

        if existing_ssa_person
          Success(existing_ssa_person)
        else
          person_hash = JSON.parse(values[:payload], symbolize_names: true)

          ssa_person = ::Ssa::Person.create(hbx_id: person_hash[:hbx_id],
                                            correlation_id: values[:correlation_id],
                                            encrypted_ssn: person_hash[:person_demographics][:encrypted_ssn],
                                            surname: person_hash[:person_name][:last_name],
                                            given_name: person_hash[:person_name][:first_name],
                                            middle_name: person_hash[:person_name][:middle_name],
                                            dob: person_hash[:person_demographics][:dob])

          return Success(ssa_person) if ssa_person.persisted?
          add_errors({ job: @job, transmission: @transmission }, "Unable to save person subject due to #{ssa_person.errors&.full_messages}",
                     :create_ssa_subject)
          status_result = update_status({ job: @job, transmission: @transmission }, :failed, "Unable to save person subject")
          return status_result if status_result.failure?
          Failure("Unable to save person subject")
        end
      end

      def create_transaction(values, subject)
        result = Fdsh::Jobs::CreateTransaction.new.call(values.merge({ transmission: @transmission,
                                                                       subject: subject,
                                                                       event: 'initial',
                                                                       state_key: :initial }))
        return result if result.success?
        add_errors({ job: @job, transmission: @transmission }, "Failed to create transaction due to #{result.failure}", :create_transaction)
        status_result = update_status({ job: @job, transmission: @transmission, transaction: @transaction }, :failed, result.failure)
        return status_result if status_result.failure?
        result
      end

      def generate_transmittable_payload(payload)
        result = Fdsh::Ssa::H3::TransformPersonToJsonSsa.new.call(payload)
        if result.success?
          @transaction.json_payload = result.value! if result.success?
          @transaction.save

          return Success(@transaction) if @transaction.json_payload
          add_errors({ job: @job, transmission: @transmission, transaction: @transaction },
                     "Unable to save transaction with payload",
                     :generate_transmittable_payload)
          status_result = update_status({ job: @job, transmission: @transmission, transaction: @transaction }, :failed,
                                        "Unable to save transaction with payload")
          return status_result if status_result.failure?
        else
          add_errors({ job: @job, transmission: @transmission, transaction: @transaction },
                     "Unable to transform payload",
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
