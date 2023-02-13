# frozen_string_literal: true

require 'mongoid-rspec'

RSpec.configure { |config| config.include Mongoid::Matchers, type: :model }
