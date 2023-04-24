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
      # primary person hbx_id
      field :contract_holder_id, type: String
      field :family_cv, type: String
      field :family_hbx_id, type: String

      index({ correlation_id: 1 })
      index({ contract_holder_id: 1 })
      index({ family_hbx_id: 1 })

      def family_cv_hash
        return if family_cv.blank?

        @family_cv_hash ||= JSON.parse(family_cv, symbolize_names: true)
      end

      def family_entity
        return if family_cv_hash.blank?

        @family_entity ||= ::AcaEntities::Operations::CreateFamily.new.call(family_cv_hash).success
      end
    end
  end
end
