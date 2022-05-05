# frozen_string_literal: true

require 'rails_helper'
require 'medicare_metadata_setup'

RSpec.describe Transaction, type: :model, dbclean: :after_each do

  context 'valid params' do
    let(:values) do
      {
        correlation_id: "id123"
      }
    end

    before do
      @transaction = described_class.new(values)
      @transaction.save!
    end

    it 'should be findable' do
      expect(described_class.find(@transaction.id)).to be_a(Transaction)
    end
  end

  context 'with a magi medicaid application and request activity' do
    let(:values) do
      primary_applicant = mm_application[:applicants].detect { |applicant| applicant[:is_primary_applicant] }
      {
        correlation_id: "id123",
        magi_medicaid_application: mm_application.to_json,
        application_id: mm_application[:hbx_id],
        primary_hbx_id: primary_applicant[:person_hbx_id]
      }
    end
    let(:mm_application) { TEST_APPLICATION_1 }

    before do
      @transaction = described_class.new(values)
      @transaction.save!
    end

    it 'should find the application id from the magi medicaid application' do
      expect(@transaction.application_id).to eq mm_application[:hbx_id]
    end

    it 'should find the primary hbx id from the magi medicaid application' do
      primary = mm_application[:applicants].detect {|applicant| applicant[:is_primary_applicant]}
      primary_hbx_id = primary[:person_hbx_id]
      expect(@transaction.primary_hbx_id).to eq primary_hbx_id
    end

    it 'should calculate the fpl year as the year before the application assistance year' do
      fpl_year = mm_application[:assistance_year] - 1
      expect(@transaction.fpl_year).to eq fpl_year
    end
  end
end