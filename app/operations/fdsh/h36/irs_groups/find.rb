# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Fdsh
  module H36
    module IrsGroups
      # Operation to find irs_group for h36.
      class Find
        include Dry::Monads[:result, :do]

        def call(params)
          values = yield validate(params)
          irs_group = yield find_irs_group(values)

          Success(irs_group)
        end

        private

        def validate(params)
          return Failure('Please provide family HBX ID') if params[:family_hbx_id].blank?
          return Failure('Please provide assistance_year') if params[:assistance_year].blank?

          Success(params)
        end

        def find_irs_group(values)
          irs_group = ::H36::IrsGroups::IrsGroup
                      .where(family_hbx_id: values[:family_hbx_id],
                             assistance_year: values[:assistance_year]).order_by(:created_at.desc).first

          if irs_group.present?
            Success(irs_group)
          else
            Failure("Unable to find irs_group with family HBX ID #{values[:family_hbx_id]} for year #{values[:assistance_year]}")
          end
        rescue StandardError
          Failure("Unable to find irs_group with family HBX ID with #{values[:family_hbx_id]} for year #{values[:assistance_year]}.")
        end
      end
    end
  end
end
