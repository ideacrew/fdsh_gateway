# frozen_string_literal: true

EventSource.configure do |config|
  config.protocols = %w[amqp http]
  config.pub_sub_root = Pathname.pwd.join('app', 'event_source')
  config.server_key = ENV['RAILS_ENV'] || Rails.env.to_sym
  config.app_name = :fdsh_gateway

  config.servers do |server|
    server.amqp do |rabbitmq|
      rabbitmq.host = ENV['RABBITMQ_HOST'] || 'amqp://localhost'
      warn rabbitmq.host
      rabbitmq.vhost = ENV['RABBITMQ_VHOST'] || '/'
      warn rabbitmq.vhost
      rabbitmq.port = ENV['RABBITMQ_PORT'] || '5672'
      warn rabbitmq.port
      rabbitmq.url = ENV['RABBITMQ_URL'] || 'amqp://localhost:5672/'
      warn rabbitmq.url
      rabbitmq.user_name = ENV['RABBITMQ_USERNAME'] || 'guest'
      warn rabbitmq.user_name
      rabbitmq.password = ENV['RABBITMQ_PASSWORD'] || 'guest'
      warn rabbitmq.password
    end

    server.amqp do |rabbitmq|
      rabbitmq.ref = 'amqp://rabbitmq:5672/event_source'
      rabbitmq.host = ENV['RABBITMQ_HOST'] || 'amqp://localhost'
      warn rabbitmq.host
      rabbitmq.vhost = ENV['RABBITMQ_VHOST'] || '/'
      warn rabbitmq.vhost
      rabbitmq.port = ENV['RABBITMQ_PORT'] || '5672'
      warn rabbitmq.port
      rabbitmq.url = ENV['RABBITMQ_URL'] || 'amqp://localhost:5672/'
      warn rabbitmq.url
      rabbitmq.user_name = ENV['RABBITMQ_USERNAME'] || 'guest'
      warn rabbitmq.user_name
      rabbitmq.password = ENV['RABBITMQ_PASSWORD'] || 'guest'
      warn rabbitmq.password
    end

    server.http do |http|
      http.ref = "http://mitc:3001"
      http.host = ENV['MITC_HOST'] || 'http://localhost'
      http.port = ENV['MITC_PORT'] || '3000'
      http.url = ENV['MITC_URL'] || 'http://localhost:3000'
    end

    server.http do |http|
      http.ref = 'https://impl.hub.cms.gov/Imp1'
      http.url =
        ENV['RIDP_INITIAL_SERVICE_URL'] || 'http://ridp-service/initial'
      http.client_certificate do |client_cert|
        client_cert.client_certificate =
          ENV['RIDP_CLIENT_CERT_PATH'] ||
            File.join(File.dirname(__FILE__), '..', 'ridp_test_cert.pem')
        client_cert.client_key =
          ENV['RIDP_CLIENT_KEY_PATH'] ||
            File.join(File.dirname(__FILE__), '..', 'ridp_test_key.key')
      end
      http.soap do |soap|
        soap.user_name = ENV['RIDP_SERVICE_USERNAME']
        soap.password = ENV['RIDP_SERVICE_PASSWORD']
        soap.password_encoding = :digest
        soap.use_timestamp = true
        soap.timestamp_ttl = 60.seconds
      end
    end
  end

  async_api_resources = ::AcaEntities.async_api_config_find_by_service_name(nil).success

      # {
      #   amqp: [nil],
      #   http: ['fdsh_gateway']
      # }
    # end

  config.async_api_schemas =
    async_api_resources.collect do |resource|
      EventSource.build_async_api_resource(resource)
    end
end

EventSource.initialize!