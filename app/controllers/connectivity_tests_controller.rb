# frozen_string_literal: true

# Connectivity tests controller
class ConnectivityTestsController < ApplicationController

  def oauth
    result = Fdsh::CheckOauthConnectivity.new.call(nil)

    @result = result.success? ? result.value! : result.failure
  end

end