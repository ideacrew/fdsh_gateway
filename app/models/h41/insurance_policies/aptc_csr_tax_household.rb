# frozen_string_literal: true

module H41
  module InsurancePolicies
    # Persistance model for a unitary H41 Transaction.
    # Composed by policy_id and tax_household_id
    class AptcCsrTaxHousehold
      include Mongoid::Document
      include Mongoid::Timestamps
      include Transmittable::Subject

      belongs_to :insurance_policy, class_name: 'H41::InsurancePolicies::InsurancePolicy'

      accepts_nested_attributes_for :insurance_policy

      # Subject
      field :subject_id, type: String
      field :tax_household_id, type: String

      # Produced by operation
      field :transaction_xml, type: String

      # index({ policy_id: 1, tax_household_id: 1 })
    end
  end
end
