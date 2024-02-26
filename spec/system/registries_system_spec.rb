# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Registries", type: :system do
  let(:user) { FactoryBot.create(:user) }

  it "shows the registries page" do
    sign_in(user)
    visit registries_path

    expect(page).to have_text('FDSH Gateway Registry Settings')
  end

  it "shows the registries page with cms eft serverless setting" do
    sign_in(user)
    visit registries_path

    expect(page).to have_text('cms_eft_serverless')
  end
end
