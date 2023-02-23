# frozen_string_literal: true

module Fdsh
  module H41
    # generates batch request zip files.
    class BuildTransmission
      include Dry::Monads[:result, :do, :try]

      TRANSMISSION_TYPES = [:all, :original, :corrected, :void].freeze

      def call(params)
        values  = yield validate(params)
        payload = yield build_transmission(values)

        Success(payload)
      end

      private

      def validate(params)
        return Failure('assistance_year required') unless params[:assistance_year]
        return Failure('report_types required') unless params[:report_types]
        # params[:excluded_policies]
        params[:report_types] = params[:report_types].uniq.map(&:to_sym)
        params[:report_types] = [:original, :corrected, :void] if params[:report_types].include?(:all)

        Success(params)
      end

      def build_transmission(values)
        values[:report_types].each do |report_type|
          ::Fdsh::H41::Transmissions::Publish(reporting_year: values[:assistance_year], kind: report_type)
        end

        Success('Successfully created transmissions')
      end
    end
  end
end
