# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transmittable::SubjectExclusion, type: :model do

  after :each do
    DatabaseCleaner.clean
  end

  context '.by_report_kind' do
    let!(:h36_exclusions) do
      create_list(:subject_exclusion, 8, report_kind: :h36)
    end

    let!(:h41_1095a_exclusions) do
      create_list(:subject_exclusion, 6, report_kind: :h41_1095a)
    end

    it 'should return exclusions of given kind' do
      expect(described_class.by_report_kind(:h36).count).to eq 8
      expect(described_class.by_report_kind(:h41_1095a).count).to eq 6
    end
  end

  context '.by_subject_name' do
    let!(:family_exclusions) do
      create_list(:subject_exclusion, 10, subject_name: 'PostedFamily')
    end

    let!(:policy_exclusions) do
      create_list(:subject_exclusion, 5, subject_name: 'InsurancePolicy')
    end

    it 'should return exclusions with given subject_name' do
      expect(described_class.by_subject_name('PostedFamily').count).to eq 10
      expect(described_class.by_subject_name('InsurancePolicy').count).to eq 5
    end
  end

  context '.active' do
    let!(:active_exclusions) do
      create_list(:subject_exclusion, 5, :active, subject_name: 'PostedFamily')
    end

    let!(:expired_exclusions) do
      create_list(:subject_exclusion, 2, :expired, subject_name: 'PostedFamily')
    end

    it 'should return active exclusions' do
      expect(described_class.active.count).to eq 5
      expect(described_class.active.map(&:id)).to eq active_exclusions.map(&:id)
    end
  end

  context '.expired' do
    let!(:active_exclusions) do
      create_list(:subject_exclusion, 3, :active, subject_name: 'PostedFamily')
    end

    let!(:expired_exclusions) do
      create_list(:subject_exclusion, 6, :expired, subject_name: 'PostedFamily')
    end

    it 'should return expired exclusions' do
      expect(described_class.expired.count).to eq 6
      expect(described_class.expired.map(&:id)).to eq expired_exclusions.map(&:id)
    end
  end
end
