# frozen_string_literal: true

module H41
  module InsurancePolicies
    # Persistence model for an InsurancePolicy.posted event Family CV
    class PostedFamily
      include Mongoid::Document
      include Mongoid::Timestamps

      has_many :insurance_policies, class_name: 'H41::InsurancePolicies::InsurancePolicy'

      accepts_nested_attributes_for :insurance_policies

      field :correlation_id, type: String
      field :contract_holder_id, type: String
      field :family_cv, type: String

      index({ correlation_id: 1 })
      index({ contract_holder_id: 1 })
    end
  end
end
