# frozen_string_literal: true

require 'dry-types'

# Extend DryTypes
module Types
  send(:include, Dry.Types)
  send(:include, Dry::Logic)
end
