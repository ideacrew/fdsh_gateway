# frozen_string_literal: true

module H41
  module InsurancePolicies
    # Persistence model for an InsurancePolicy.posted event Family CV
    class InsurancePolicy
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :posted_family, class_name: 'H41::InsurancePolicies::PostedFamily'
      has_many :tax_households, class_name: 'H41::InsurancePolicies::TaxHousehold'

      accepts_nested_attributes_for :tax_households, :posted_family

      field :policy_id, type: String
      field :assistance_year, type: Integer

      index({ assistance_year: 1, policy_id: 1 })
    end
  end
end
