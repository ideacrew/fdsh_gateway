# frozen_string_literal: true

require 'faraday'

module Jwt
  # Request a JWT from the CMS service
  class GetJwt
    include Dry::Monads[:result, :do, :try]

    def call(_params)
      fetch_jwt
    end

    protected

    def fetch_jwt
      host = ENV['TOKEN_HOST'] || 'https://impl.hub.cms.gov'
      path = ENV['TOKEN_PATH'] || 'auth/oauth/v2/token'
      token_response = Rails.cache.fetch("cms_access_token", expires_in: 29.minutes.to_i, race_condition_ttl: 5.seconds) do
        auth_conn = Faraday.new(url: host)
        response = auth_conn.post(path, grant_type: "client_credentials", client_id: ENV.fetch('TOKEN_CLIENT_ID', nil),
                                        client_secret: ENV.fetch('TOKEN_CLIENT_SECRET', nil))
        return Failure("Non JSON response for JWT request") unless json?(response.env.response_body)
        resp = JSON.parse(response.env.response_body, symbolize_names: true)

        break if resp[:errors]

        resp[:access_token]
      end
      token_response ? Success(token_response) : Failure("Unable to fetch JWT")
    rescue StandardError => e
      Failure("Error while fetching JWT: #{e.message}")
    end

    def json?(response)
      !JSON.parse(response).nil?
    rescue StandardError
      false
    end

  end
end
