# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      # Operation to publish an open transmission of given kind
      class Publish1095aPayload
        include Dry::Monads[:result, :do, :try]

        H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

        def call(params)
          values                = yield validate(params)
          transactions          = yield fetch_transactions(values[:transmission])
          subjects              = yield fetch_subjects(transactions)
          grouping_result       = yield group_subjects_by_family_hbx_id(subjects)
          result                = yield transform_and_publish_notice_event(grouping_result, values)

          Success(result)
        end

        private

        def validate(params)
          return Failure('transmission required') unless params[:transmission]
          return Failure('reporting year required') unless params[:reporting_year]
          return Failure('report_type required ') unless params[:report_type]
          unless params[:report_type] && H41_TRANSMISSION_TYPES.include?(params[:report_type])
            return Failure("report_type must be one #{H41_TRANSMISSION_TYPES.map(&:to_s).join(', ')}")
          end

          @logger = Logger.new(
            "#{Rails.root}/log/publish_1095a_payload_errors_#{Date.today.strftime('%Y_%m_%d_%s')}.log"
          )

          Success(params)
        end

        def fetch_transactions(transmission)
          Success(transmission.transactions.transmitted)
        end

        def fetch_subjects(transactions)
          subjects = ::H41::InsurancePolicies::AptcCsrTaxHousehold.where(:id.in => transactions.pluck(:transactable_id))
          subjects.present? ? Success(subjects) : Failure("No valid transactions present")
        end

        def group_subjects_by_family_hbx_id(subjects)
          result = subjects.group_by do |tax_household|
            tax_household.insurance_policy.posted_family.family_hbx_id
          end

          Success(result.transform_values { |values| values.pluck(:hbx_assigned_id) })
        end

        def transform_and_publish_notice_event(group_result, values)
          exclusion_records = Transmittable::SubjectExclusion.by_subject_name('PostedFamily').active.pluck(:subject_id)
          group_result.each do |family_hbx_id, subject_hbx_ids|
            next if exclusion_records.include?(family_hbx_id)

            family_hash = ::Fdsh::H41::Transmissions::TransformFamilyPayload.new.call({ family_hbx_id: family_hbx_id,
                                                                                        subject_hbx_ids: subject_hbx_ids,
                                                                                        reporting_year: values[:reporting_year],
                                                                                        report_type: values[:report_type] })
            if family_hash.failure?
              @logger.error(
                "Family failing validation contract with errors #{family_hash.errors} for family with hbx_id#{family_hbx_id}"
              )
              next
            end

            publish_1095a_family_payload(family_hash, values)
          rescue StandardError => e
            @logger.error(
              "Unable to publish payload for family with hbx_id #{family_hbx_id} due to #{e.backtrace}"
            )
          end
          Success(true)
        end

        def validate_family_json_hash(posted_family)
          family_hash = JSON.parse(posted_family.family_cv, symbolize_names: true)
          validation_result = AcaEntities::Contracts::Families::FamilyContract.new.call(family_hash)
          validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
        end

        def publish_1095a_family_payload(family_hash, values)
          case values[:report_type]
          when :void
            publish_void_notice_event(family_hash, values)
          when :corrected
            publish_corrected_notice_event(family_hash, values)
          when :original
            publish_initial_notice_event(family_hash, values)
          else
            true
          end
        end

        def publish_void_notice_event(family_hash, values)
          event = event('events.fdsh_gateway.irs1095as.void_notice_requested',
                        attributes: family_hash, headers: { assistance_year: values[:reporting_year],
                                                            notice_type: values[:report_type] })
          event.publish
        end

        def publish_corrected_notice_event(family_hash, values)
          event = event('events.fdsh_gateway.irs1095as.corrected_notice_requested',
                        attributes: family_hash, headers: { assistance_year: values[:reporting_year],
                                                            notice_type: values[:report_type] })
          event.publish
        end

        def publish_initial_notice_event(family_hash, values)
          event = event('events.fdsh_gateway.irs1095as.initial_notice_requested',
                        attributes: family_hash, headers: { assistance_year: values[:reporting_year],
                                                            notice_type: values[:report_type] })
          event.publish
        end
      end
    end
  end
end
