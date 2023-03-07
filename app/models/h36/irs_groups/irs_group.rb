# frozen_string_literal: true

module H36
  module IrsGroups
    # Persistence model for an InsurancePolicy.posted event Family CV
    class IrsGroup
      include Mongoid::Document
      include Mongoid::Timestamps
      include ::Transmittable::Subject

      field :correlation_id, type: String
      field :contract_holder_hbx_id, type: String
      field :family_hbx_id, type: String
      field :family_cv, type: String
      field :assistance_year, type: Integer
      field :transaction_xml, type: String

      index({ assistance_year: 1 })
      index({ correlation_id: 1 })
      index({ contract_holder_id: 1 })
      index({ family_hbx_id: 1 })
      index({ transaction_xml: 1 })
    end
  end
end
