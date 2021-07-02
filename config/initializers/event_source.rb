# frozen_string_literal: true

EventSource.configure do |config|
  config.protocols = %w[amqp http]
  config.pub_sub_root =
    Pathname.pwd.join('spec', 'rails_app', 'app', 'event_source')

  config.server_key = ENV['RAILS_ENV'] || Rails.env.to_sym

  config.servers do |server|
    server.amqp do |rabbitmq|
      rabbitmq.url = ENV['RABBITMQ_URL'] || 'amqp://localhost:5672/'
      warn rabbitmq.url
      rabbitmq.user_name = ENV['RABBITMQ_USERNAME'] || 'guest'
      warn rabbitmq.user_name
      rabbitmq.password = ENV['RABBITMQ_PASSWORD'] || 'guest'
      warn rabbitmq.password
      # rabbitmq.url = "" # ENV['RABBITMQ_URL']
    end

    server.http do |http|
      http.ref = "http://ridp-service/endpoint"
      http.url = ENV["RIDP_INITIAL_SERVICE_URL"] || "http://ridp-service/initial"
      http.client_certificate do |client_cert|
        client_cert.client_certificate = ENV["RIDP_CLIENT_CERT_PATH"] ||
                                         File.join(File.dirname(__FILE__), "..", "ridp_test_cert.pem")
        client_cert.client_key = ENV["RIDP_CLIENT_KEY_PATH"] ||
                                 File.join(File.dirname(__FILE__), "..", "ridp_test_key.key")
      end
      http.soap do |soap|
        soap.user_name = ENV["RIDP_SERVICE_USERNAME"]
        soap.password = ENV["RIDP_SERVICE_PASSWORD"]
        soap.password_encoding = :digest
        soap.use_timestamp = true
        soap.timestamp_ttl = 60.seconds
      end
    end
  end

  app_schemas =
    Gem
    .loaded_specs
    .values
    .inject([]) do |ps, s|
      ps.concat(s.matches_for_glob('aca_entities/async_api/fdsh_gateway/*.yml'))
    end

  config.async_api_schemas =
    app_schemas.map do |schema|
      EventSource::AsyncApi::Operations::AsyncApiConf::LoadPath
        .new
        .call(path: schema)
        .value!
    end

  # config.asyncapi_resources = [AcaEntities::AsyncApi::MedicaidGataway]
  # config.asyncapi_resources = AcaEntities.find_resources_for(:enroll, %w[amqp resque_bus]) # will give you resouces in array of hashes form
  # AcaEntities::Operations::AsyncApi::FindResource.new.call(self)
end

EventSource.initialize!
