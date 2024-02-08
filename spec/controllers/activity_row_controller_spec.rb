# frozen_string_literal: true

require 'rails_helper'

# Spec for ActivityRowController
RSpec.describe ActivityRowController, type: :controller, dbclean: :after_each do

  let(:transaction) { ActivityRow.create({ correlation_id: "id123" })}
  let(:user) { FactoryBot.create(:user) }

  before :each do
    sign_in user
  end

  describe 'GET index' do
    before { get :index }

    it 'returns success' do
      expect(response).to have_http_status(:success)
    end

    it "updates the last activity_at date" do
      user.reload
      expect(user.last_activity_at).not_to be_nil
    end
  end

end