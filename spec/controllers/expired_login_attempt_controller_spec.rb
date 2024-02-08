# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityRowController,
               "attempting to log in an as an expired user, even with correct permissions",
               dbclean: :after_each do

  let(:user) do
    user_record = FactoryBot.create(:user)
    user_record.last_activity_at = Time.now - 180.days
    user_record.save!
    user_record
  end

  before :each do
    sign_in user
  end

  context 'when account is expired' do

    it 'redirects to the sign in page' do
      get :index
      expect(response).to redirect_to("http://test.host/users/sign_in")
    end
  end

  context "when account is active" do

    before { user.update(last_activity_at: Time.now) }

    it "logs in successfully" do
      get :index
      expect(response.status).to eql(200)
    end
  end
end