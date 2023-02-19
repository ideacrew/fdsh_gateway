# frozen_string_literal: true

module Accounts
  # A Single Sign-on (SSO) identity assigned to a person or service for
  # accessing multiple client services.
  class Account
    include Mongoid::Document
    include Mongoid::Timestamps

    field :username, type: String
  end
end
