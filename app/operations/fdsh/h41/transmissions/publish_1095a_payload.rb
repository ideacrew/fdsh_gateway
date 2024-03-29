# frozen_string_literal: true

module Fdsh
  module H41
    module Transmissions
      # Operation to publish an open transmission of given kind
      class Publish1095aPayload
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        H41_TRANSMISSION_TYPES = [:corrected, :original, :void].freeze

        def call(params)
          values                = yield validate(params)
          transactions          = yield fetch_transactions(values[:transmission])
          grouping_result       = yield group_policies_by_family_hbx_id(transactions)
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
          transactions = transmission.transactions.transmitted
          transactions.blank? ? Failure("No valid transactions present") : Success(transactions)
        end

        def group_policies_by_family_hbx_id(transactions)
          result = transactions.inject({}) do |data, transaction|
            subject = transaction.transactable
            family_hbx_id = subject.insurance_policy.posted_family.family_hbx_id
            data[family_hbx_id] ||= []
            data[family_hbx_id] << subject.insurance_policy_id
            data
          end

          Success(result)
        end

        def transform_and_publish_notice_event(group_result, values)
          exclusion_records = Transmittable::SubjectExclusion.by_subject_name('PostedFamily').active.pluck(:subject_id)
          group_result.each do |family_hbx_id, insurance_policy_ids|
            next if exclusion_records.include?(family_hbx_id)
            policies = ::H41::InsurancePolicies::InsurancePolicy.in(id: insurance_policy_ids)
            policy_hbx_ids = policies.pluck(:policy_hbx_id)
            family_hash = ::Fdsh::H41::Transmissions::TransformFamilyPayload.new.call({ family_hbx_id: family_hbx_id,
                                                                                        insurance_policy_ids: insurance_policy_ids,
                                                                                        reporting_year: values[:reporting_year],
                                                                                        report_type: values[:report_type] })
            if family_hash.failure?
              @logger.error(
                "Family failing validation contract with errors #{family_hash.errors} for family with hbx_id#{family_hbx_id}"
              )
              next
            end
            values[:affected_policies] = policy_hbx_ids
            publish_1095a_family_payload(family_hash.value!.to_h, values)
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
                                                            notice_type: values[:report_type],
                                                            affected_policies: values[:policy_hbx_ids] })
          event.success.publish
        end

        def publish_corrected_notice_event(family_hash, values)
          event = event('events.fdsh_gateway.irs1095as.corrected_notice_requested',
                        attributes: family_hash, headers: { assistance_year: values[:reporting_year],
                                                            notice_type: values[:report_type],
                                                            affected_policies: values[:policy_hbx_ids] })
          event.success.publish
        end

        def publish_initial_notice_event(family_hash, values)
          event = event('events.fdsh_gateway.irs1095as.initial_notice_requested',
                        attributes: family_hash, headers: { assistance_year: values[:reporting_year],
                                                            notice_type: values[:report_type],
                                                            affected_policies: values[:policy_hbx_ids] })
          event.success.publish
        end
      end
    end
  end
end
