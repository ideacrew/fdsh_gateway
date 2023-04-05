# frozen_string_literal: true

module Fdsh
  module H36
    module IrsGroups
      # Adds a Family to the database for H36 transmission to CMS
      class UpdateAndCloneTransactions
        include Dry::Monads[:result, :do]

        TOTAL_MONTHS_IN_YEAR = 12

        def call(params)
          values                           = yield validate(params)
          prior_transmission               = yield fetch_prior_open_transmission(values)
          current_transmission             = yield create_new_open_transmission(values)
          _transactions                    = yield clone_transactions(prior_transmission, current_transmission, values)
          result                           = yield build_and_persist_xml(prior_transmission, values)

          Success(result)
        end

        private

        def validate(params)
          errors = []
          errors << 'assistance_year missing' unless params[:assistance_year]
          errors << 'month_of_year missing' unless params[:month_of_year]

          if errors.empty?
            set_assistance_year(params)
            set_month_of_year(params)
            Success(params)
          else
            Failure(errors)
          end
        end

        def fetch_transmission(assistance_year, month)
          Fdsh::H36::Transmissions::Find.new.call({ assistance_year: assistance_year,
                                                    month_of_year: month })
        end

        def set_assistance_year(values)
          @assistance_year = if values[:month_of_year] == 1
                    values[:assistance_year] - 1
                  else
                    values[:assistance_year]
                  end
        end

        def set_month_of_year(values)
          @month = if values[:month_of_year] == 1
                               12
                             else
                               values[:month_of_year] - 1
                             end
        end

        def fetch_prior_open_transmission(values)
          result = fetch_transmission(@assistance_year, @month)

          if result.success?
            # Update to pending only if transmission is in current year
            update_prior_transmission_to_pending_state(result.success) if values[:month_of_year] != 1
            result
          else
            Failure("No prior_transmission exists")
          end
        end

        def create_new_open_transmission(values)
          result = ::Fdsh::H36::Transmissions::Create.new.call({
                                                                 assistance_year: values[:assistance_year],
                                                                 month_of_year: values[:month_of_year]
                                                               })
          if result.success?
            result
          else
            Failure("Unable to create open transmission")
          end
        end

        def clone_transactions(prior_transmission, current_transmission, values)
          prior_transactions = prior_transmission.transactions.transmit_pending
          assign_transactions_to_transmission(current_transmission, prior_transactions, values)
          Success(true)
        end

        def clone_subject_and_create_transaction(transaction, values)
          subject = transaction.transactable
          irs_group = ::H36::IrsGroups::IrsGroup.create!(
            correlation_id: subject.correlation_id,
            family_cv: subject.family_cv,
            family_hbx_id: subject.family_hbx_id,
            contract_holder_hbx_id: subject.contract_holder_hbx_id,
            assistance_year: values[:assistance_year]
          )
          ::Transmittable::Transaction.create!(transmit_action: :transmit,
                                               status: :created, started_at: Time.now,
                                               transactable: irs_group)
        end

        def assign_transactions_to_transmission(transmission, prior_transactions, values)
          limit = 1000
          offset = 0
          total_count = prior_transactions.count

          while offset <= total_count
            prior_transactions.offset(offset).limit(limit).no_timeout.each do |transaction|
              next if check_if_transaction_transmission_exists?(transaction, transmission)

              new_transaction = clone_subject_and_create_transaction(transaction, values)
              ::Transmittable::TransactionsTransmissions.create(
                transmission: transmission,
                transaction: new_transaction
              )
            end
            offset += limit
          end
        end

        def check_if_transaction_transmission_exists?(transaction, transmission)
          ::Transmittable::TransactionsTransmissions.where(transaction_id: transaction.id,
                                                           transmission_id: transmission.id).first.present?
        end

        def update_prior_transmission_to_pending_state(prior_transmission)
          prior_transmission.update!(status: :pending)
        end

        def build_and_persist_xml(prior_transmission, values)
          if values[:assistance_year] != prior_transmission.reporting_year
            return Success("Build xml not needed if prior transmission year is not same as input assistance year")
          end

          # send transactions as well
          ::Fdsh::H36::Request::BuildAndPersistH36Xml.new.call({ transmission: prior_transmission,
                                                                 assistance_year: @assistance_year,
                                                                 month_of_year: @month })
        end
      end
    end
  end
end
