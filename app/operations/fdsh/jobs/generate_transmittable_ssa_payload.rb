# frozen_string_literal: true

module Fdsh
  module Jobs
    # create job operation that takes params of key (required), started_at(required), publish_on(required), payload (required)
    class GenerateTransmittableSsaPayload
      include ::Fdsh::Jobs::Transmittable::TransmittableUtils

      def call(params)
        values = yield validate_params(params)
        @job = yield find_or_create_job_by_job_id(values)
        @job = yield generate_message_id
        transmission_params = yield construct_request_transmission_params(values)
        @transmission = yield create_request_transmission(transmission_params)
        person_subject = yield create_person_subject(values)
        transaction_params = yield construct_request_transaction_params(values, person_subject)
        @transaction = yield create_request_transaction(transaction_params)
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

      def generate_message_id
        @job.generate_message_id

        if @job.message_id.present?
          Success(@job)
        else
          add_errors(:generate_message_id, "Unable to generate message id for job", { job: @job })
          status_result = update_status(:failed, "Unable to generate message id for job", { job: @job })
          return status_result if status_result.failure?
          Failure("Unable to generate message id for job")
        end
      end

      def construct_request_transmission_params(values)
        values[:key] = :ssa_verification_request
        values[:event] = 'initial'
        values[:state_key] = :initial
        values[:job] = @job
        Success(values)
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

      def construct_request_transaction_params(values, person)
        values[:key] = :ssa_verification_request
        values[:event] = 'initial'
        values[:state_key] = :initial
        values[:job] = @job
        values[:transmission] = @transmission
        values[:subject] = person
        Success(values)
      end

      def generate_transmittable_payload(payload)
        result = Fdsh::Ssa::H3::TransformPersonToJsonSsa.new.call(payload)
        if result.success?
          @transaction.json_payload = result.value! if result.success?
          @transaction.save

          return Success(@transaction) if @transaction.json_payload
          add_errors(:generate_transmittable_payload,
                     "Unable to save transaction with payload",
                     { job: @job, transmission: @transmission, transaction: @transaction })
          status_result = update_status(:failed,
                                        "Unable to save transaction with payload",
                                        { job: @job, transmission: @transmission, transaction: @transaction })
        else
          add_errors(:generate_transmittable_payload,
                     "Unable to transform payload",
                     { job: @job, transmission: @transmission, transaction: @transaction })
          status_result = update_status(:failed, "Unable to transform payload",
                                        { job: @job, transmission: @transmission, transaction: @transaction })
        end
        status_result.failure? ? status_result : result
      end

      def transmittable
        message_id = @job.message_id

        if @transaction.json_payload && message_id
          Success({ transaction: @transaction,
                    message_id: message_id })
        else
          add_errors(:transmittable,
                     "Transaction do not consists of a payload or no message id found",
                     { job: @job, transmission: @transmission, transaction: @transaction })
          status_result = update_status(:failed,
                                        "Transaction do not consists of a payload or no message id found",
                                        { job: @job, transmission: @transmission, transaction: @transaction })
          return status_result if status_result.failure?
          Failure("Transaction do not consists of a payload or no message id found")
        end
      end
    end
  end
end
