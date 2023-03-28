# frozen_string_literal: true

require 'rails_helper'

RSpec.describe H41::Transmissions::Outbound::OriginalTransmission, type: :model do
  before :each do
    DatabaseCleaner.clean
  end

  describe 'attributes' do
    it { is_expected.to have_field(:reporting_year).of_type(Integer) }
    it { is_expected.to have_field(:report_kind).of_type(Symbol) }
  end
end
