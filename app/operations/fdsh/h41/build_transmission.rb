# frozen_string_literal: true

module Fdsh
  module H41
    # generates batch request zip files.
    class BuildTransmission
      include Dry::Monads[:result, :do, :try]

      REPORT_TYPES = [:all, :original, :corrected, :void].freeze

      def call(params)
        values  = yield validate(params)
        payload = yield build_transmission(values)

        Success(payload)
      end

      private

      def validate(params)
        errors = []
        errors << Failure('assistance_year required') unless params[:assistance_year]
        errors << Failure('report_types required') unless params[:report_types]
        params[:report_types] = params[:report_types].map(&:to_sym).uniq
        invalid_report_types = params[:report_types] - REPORT_TYPES
        errors << "invalid report type #{invalid_report_types}" if invalid_report_types.present?
        params[:report_types] = [:original, :corrected, :void] if params[:report_types].include?(:all)

        errors.present? ? Failure(errors) : Success(params)
      end

      def build_transmission(values)
        values[:report_types].each do |report_type|
          publish_service.call(
            reporting_year: values[:assistance_year],
            report_type: report_type,
            deny_list: values[:deny_list],
            allow_list: values[:allow_list]
          )
        end

        Success(values)
      end

      def publish_service
        @publish_service ||= ::Fdsh::H41::Transmissions::Publish.new
      end
    end
  end
end

