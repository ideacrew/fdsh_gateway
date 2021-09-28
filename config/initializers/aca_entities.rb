# frozen_string_literal: true

AcaEntities::Configuration::Encryption.configure do |config|
  config.encrypted_key = ENV['SYMMETRIC_ENCRYPTION_ENCRYPTED_KEY'] || "1234567890ABCDEF"
  config.encrypted_iv = ENV['SYMMETRIC_ENCRYPTION_ENCRYPTED_IV'] || "1234567890ABCDEF"
  config.private_rsa_key = ENV['ENROLL_SYMMETRIC_ENCRYPTION_PRIVATE_KEY'] || "1234567890ABCDEF"
  config.app_env = Rails.env
end