# frozen_string_literal: true

require 'rails_helper'

# Spec for ActivityRowController
RSpec.describe RegistriesController, type: :controller, dbclean: :after_each do

  let(:user) { FactoryBot.create(:user) }

  before :each do
    sign_in user
  end

  describe 'GET index' do
    before { get :index }

    it 'returns success' do
      expect(response).to have_http_status(:success)
    end
  end
end
