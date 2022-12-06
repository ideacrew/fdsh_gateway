# frozen_string_literal: true

require 'rails_helper'

# Spec for TransactionsController
RSpec.describe TransactionsController, type: :controller, dbclean: :after_each do

  let(:transaction) { Transaction.create({ correlation_id: "id123" })}
  let(:user) { FactoryBot.create(:user) }

  before :each do
    sign_in user
  end

  describe 'GET show' do
    it 'returns success' do
      get :show, params: { id: transaction.id }
      expect(response).to have_http_status(:success)
    end
  end
end