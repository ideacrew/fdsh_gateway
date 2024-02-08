# frozen_string_literal: true

# ApplicationController is the main controller from which all other controllers in the application inherit.
# It includes a before action that ensures a user is authenticated for all actions in any controller that inherits from ApplicationController.
#
# @!method authenticate_user!
#   @abstract
#   @return [void] This method is expected to be implemented in a subclass or included module to handle user authentication.
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
end
