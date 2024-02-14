# frozen_string_literal: true

module Fdsh
  module Jobs
    module Transmittable
      # This module is designed for code reuse within domain operations that include Transmittable related objects.
      # It provides a set of generic methods or steps specifically tailored for Transmittable 2.0 functionality.
      # The methods within this module are focused on the finding and creation of Job, Transmission, Transaction, Error, and ProcessStatus objects,
      # offering a modular and reusable solution for related operations within the domain.
      # Operations are the classes that include EventSource::Command and Dry::Monads[:result, :do].
      module TransmittableUtils
        include EventSource::Command
        include Dry::Monads[:result, :do]

        # @param [Hash] opts The options to create a transmittable job
        # @option opts [Hash] :job_params The params to create a job
        # @return [Dry::Monads::Result]
        def create_job(job_params)
          Fdsh::Jobs::CreateJob.new.call(job_params)
        end

        # @param [Hash] opts The options to find or create a transmittable job
        # @option opts [Hash] :job_params The params to find or create a job
        # @return [Dry::Monads::Result]
        def find_or_create_job_by_job_id(job_params)
          Fdsh::Jobs::FindOrCreateJob.new.call(job_params)
        end

        # @param [Hash] opts The options to create a request transmittable transaction
        # @option opts [Hash, Transmittable::Job]
        #   :transaction_params The params to create a transaction
        #   :job The job to create a transaction for
        # @return [Dry::Monads::Result]
        def create_request_transaction(transaction_params)
          result = ::Fdsh::Jobs::CreateTransaction.new.call(transaction_params)
          return result if result.success?

          add_errors(
            :create_request_transaction,
            "Failed to create transaction due to #{result.failure} for params: #{transaction_params}",
            { job: transaction_params[:job], transmission: transaction_params[:transmission] }
          )
          status_result = update_status(:failed, result.failure,
                                        { job: transaction_params[:job], transmission: transaction_params[:transmission] })
          status_result.failure? ? status_result : result
        end

        # @param [Hash] opts The options to create a request transmittable transmission
        # @option opts [Hash, Transmittable::Job]
        #   :transmission_params The params to create a transmission
        #   :job The job to create a transmission for
        # @return [Dry::Monads::Result]
        def create_request_transmission(transmission_params)
          result = ::Fdsh::Jobs::CreateTransmission.new.call(transmission_params)
          return result if result.success?

          add_errors(
            :create_request_transmission,
            "Failed to create transmission due to #{result.failure} for params: #{transmission_params}",
            { job: transmission_params[:job] }
          )
          status_result = update_status(:failed, result.failure, { job: transmission_params[:job] })
          status_result.failure? ? status_result : result
        end

        # @param [Hash] transmission_params The parameters for creating the response transmission.
        # @param [Hash] transmittable_objects A hash containing transmittable objects.
        # @option transmittable_objects [Object] :job The Transmittable::Job.
        # @option transmittable_objects [Object] :transmission The request Transmittable::Transmission.
        # @option transmittable_objects [Object] :transaction The request Transmittable::Transaction.
        # @return [Dry::Monads::Result]
        def create_response_transmission(transmission_params)
          result = ::Fdsh::Jobs::CreateTransmission.new.call(transmission_params)
          return result if result.success?

          add_errors(
            :create_response_transmission,
            "Failed to create transmission due to #{result.failure} for params: #{transmission_params}",
            { job: transmission_params[:job] }
          )
          status_result = update_status(:failed, result.failure, { job: transmission_params[:job] })
          status_result.failure? ? status_result : result
        end

        # @param [Hash] transaction_params The parameters for creating the response transaction.
        # @param [Hash] transmittable_objects A hash containing transmittable objects.
        # @option transmittable_objects [Object] :job The Transmittable::Job.
        # @option transmittable_objects [Object] :transmission The request Transmittable::Transmission.
        # @option transmittable_objects [Object] :transaction The request Transmittable::Transaction.
        # @return [Dry::Monads::Result]
        def create_response_transaction(transaction_params)
          result = ::Fdsh::Jobs::CreateTransaction.new.call(transaction_params)
          return result if result.success?

          add_errors(
            :create_response_transaction,
            "Failed to create transaction due to #{result.failure} for params: #{transaction_params}",
            { job: transaction_params[:job], transmission: transaction_params[:transmission] }
          )
          status_result = update_status(:failed, result.failure,
                                        { job: transaction_params[:job], transmission: transaction_params[:transmission] })
          status_result.failure? ? status_result : result
        end

        # @param [Hash] opts The options to update the transmittable process status
        # @option opts [String, Symbol, Hash]
        #   :message The message to update the process status with
        #   :state The state to update the process status with
        #   :transmittable_objects The transmittable objects to update the process status for
        # @return [Dry::Monads::Result]
        def update_status(state, message, transmittable_objects)
          ::Fdsh::Jobs::UpdateProcessStatus.new.call(
            {
              message: message,
              state: state,
              transmittable_objects: transmittable_objects
            }
          )
        end

        # @param [Hash] opts The options to add errors
        # @option opts [Symbol, String, Hash]
        #   :error_key The key to identify the transmittable object
        #   :message The error message
        #   :transmittable_objects The transmittable objects to add errors to
        # @return [Dry::Monads::Result]
        def add_errors(error_key, message, transmittable_objects)
          ::Fdsh::Jobs::AddError.new.call(
            {
              key: error_key,
              message: message,
              transmittable_objects: transmittable_objects
            }
          )
        end
      end
    end
  end
end
