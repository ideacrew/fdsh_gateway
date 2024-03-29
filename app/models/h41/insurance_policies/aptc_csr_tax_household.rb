# frozen_string_literal: true

module H41
  module InsurancePolicies
    # Persistance model for a unitary H41 Transaction.
    # Composed by policy_id and tax_household_id
    class AptcCsrTaxHousehold
      include Mongoid::Document
      include Mongoid::Timestamps
      include Transmittable::Subject

      belongs_to :insurance_policy, class_name: 'H41::InsurancePolicies::InsurancePolicy', index: true

      accepts_nested_attributes_for :insurance_policy

      field :hbx_assigned_id, type: String

      # A new instance of AptcCsrTaxHousehold is not new unless there is a change in :primary_tax_filer_hbx_id
      # Unique identifier to find an AptcCsrTaxHousehold
      field :primary_tax_filer_hbx_id, type: String

      # Produced by operation
      field :transaction_xml, type: String

      field :corrected, type: Boolean
      field :original, type: Boolean
      field :void, type: Boolean

      # indexes
      index({ hbx_assigned_id: 1 })
      index({ primary_tax_filer_hbx_id: 1 })
      index({ corrected: 1 })
      index({ original: 1 })
      index({ void: 1 })
      index({ corrected: 1, original: 1, void: 1 })

      # Scopes
      scope :by_hbx_assigned_id, ->(hbx_assigned_id) { where(hbx_assigned_id: hbx_assigned_id) }
      scope :by_primary_tax_filer_hbx_id, ->(primary_tax_filer_hbx_id) { where(primary_tax_filer_hbx_id: primary_tax_filer_hbx_id) }
      scope :corrected, -> { where(corrected: true, original: false, void: false) }
      scope :original,  -> { where(corrected: false, original: true, void: false) }
      scope :void,      -> { where(corrected: false, original: false, void: true) }
    end
  end
end
