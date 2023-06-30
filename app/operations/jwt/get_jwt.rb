# frozen_string_literal: true

module Jwt
  # Request a JWT from the CMS service
  class JwtTransmissions
    include Dry::Monads[:result, :do, :try]

    def call(params)
      validated_params = yield validate_params(params)
      jwt_request_transmission = yield create_jwt_request_transmission(validated_params)
      # operation below doesn't exist yet!
      _jwt = yield Jwt::GetJwt.new.call(jwt_request_transmission)
      # transaction = yield update_request_transaction(request_transaction, jwt)
      # _jwt_response_transmission = yield create_jwt_response_transmission(jwt, transaction, validated_params[:job])
      Success(jwt)
    end

    protected

    def validate_params(params)
      return Failure('transaction required') unless params[:transaction]
      return Failure('job required') unless params[:job]
      # return Failure('key required') unless params[:key]

      Success(params)
    end

    def create_jwt_request_transmission(values)
      transmission = create_transmission(:jwt_response, :initial)
      create_transactions_transmissions(transmission, values[:transaction])
      Success(transmission)
    end

    # def update_request_transaction(transaction, jwt)
    #   transaction.payload.merge!({ token: jwt })
    #   transaction.save
    #   Success(transaction)
    # end

    def create_jwt_response_transmission(_jwt, transaction)
      # get status from response?
      # create new transmission for the given job, with a key of :jwt_response, status from above
      transmission = create_transmission(:jwt_response, status)
      # create a transactions_transmissions entry between the given transaction and the transmission
      create_transactions_transmissions(transmission, transaction)
    end

    def create_transmission(key, _state)
      params = {
        key: key,
        title: key.humanize.titlecase,
        started_at: DateTime.now,
        # process_status: create_process_status, # generic initial process status! maybe move that to aca_entities?
        errors: [],
        payload: payload
      }
      # the operation below doesn't exist yet!
      transmission = AcaEntities::Protocols::Transmittable::Operations::Transmission.new.call(params)
      transmission.save
    end

    def create_transactions_transmissions(transmission, transaction)
      ::Transmittable::TransactionsTransmissions.create(
        transmission: transmission,
        transaction: transaction
      )
    end
  end
end