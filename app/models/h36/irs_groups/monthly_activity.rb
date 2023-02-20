# frozen_string_literal: true

module H36
  module IrsGroups
    # Persistence model for an InsurancePolicy.posted event Family CV
    class MonthlyActivity
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :irs_group, class_name: "H36::IrsGroups::IrsGroup"

      field :assistance_year, type: Integer
      field :month_of_year, type: Integer
      field :transaction_xml, type: String

      index({ assistance_year: 1 })
      index({ assistance_year: 1, month_of_year: 1 })
      index({ transaction_xml: 1 })
    end
  end
end
