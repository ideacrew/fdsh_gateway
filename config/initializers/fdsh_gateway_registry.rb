# frozen_string_literal: true

FdshGatewayRegistry = ResourceRegistry::Registry.new

FdshGatewayRegistry.configure do |config|
  config.name       = :fdsh_gateway
  config.created_at = DateTime.now
  config.load_path  = Rails.root.join('system', 'config', 'templates', 'features').to_s
end
