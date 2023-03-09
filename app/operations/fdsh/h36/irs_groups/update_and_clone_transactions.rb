# frozen_string_literal: true

module Fdsh
  module H36
    module IrsGroups
      # Adds a Family to the database for H36 transmission to CMS
      class UpdateAndCloneTransactions
        include Dry::Monads[:result, :do]

        TOTAL_MONTHS_IN_YEAR = 12

        def call(params)
          values                       = yield validate(params)
          _year_and_month              = yield assign_year_and_month(values)
          prior_transmission           = yield fetch_prior_open_transmission
          current_transmission         = yield create_new_open_transmission
          _transactions                = yield clone_transactions(prior_transmission, current_transmission)
          result                       = yield build_and_persist_xml(prior_transmission)

          Success(result)
        end

        private

        def validate(params)
          errors = []
          errors << 'assistance_year missing' unless params[:assistance_year]
          errors << 'month_of_year missing' unless params[:month_of_year]

          errors.empty? ? Success(params) : Failure(errors)
        end

        def fetch_transmission(assistance_year, month)
          Fdsh::H36::Transmissions::Find.new.call({ assistance_year: assistance_year,
                                                    month_of_year: month })
        end

        def assign_year_and_month(values)
          assign_assistance_year(values)
          assign_month(values)
          Success(true)
        end

        def assign_assistance_year(values)
          @assistance_year = values[:assistance_year]
        end

        def assign_month(values)
          @month = if @assistance_year == (Date.today.year - 1) && values[:month_of_year] == Date.today.month
                     TOTAL_MONTHS_IN_YEAR + values[:month_of_year]
                   else
                     values[:month_of_year]
                   end
        end

        def fetch_prior_open_transmission
          result = fetch_transmission(@assistance_year, @month - 1)
          if result.success?
            update_prior_transmission_to_pending_state(result.success)
            result
          else
            Failure("No prior_transmission exists")
          end
        end

        def create_new_open_transmission
          result = ::Fdsh::H36::Transmissions::Create.new.call({
                                                                 assistance_year: @assistance_year,
                                                                 month_of_year: @month
                                                               })
          if result.success?
            result
          else
            Failure("Unable to create open transmission")
          end
        end

        def clone_transactions(prior_transmission, current_transmission)
          prior_transactions = prior_transmission.transactions.transmit_pending
          assign_transactions_to_transmission(current_transmission, prior_transactions)
          Success(true)
        end

        def clone_subject_and_create_transaction(transaction)
          subject = transaction.transactable
          irs_group = ::H36::IrsGroups::IrsGroup.create!(
            correlation_id: subject.correlation_id,
            family_cv: subject.family_cv,
            family_hbx_id: subject.family_hbx_id,
            contract_holder_hbx_id: subject.contract_holder_hbx_id,
            assistance_year: subject.assistance_year
          )
          ::Transmittable::Transaction.create!(transmit_action: :transmit,
                                               status: :created, started_at: Time.now,
                                               transactable: irs_group)
        end

        def assign_transactions_to_transmission(transmission, prior_transactions)
          limit = 1000
          offset = 0
          total_count = prior_transactions.count

          while offset <= total_count
            prior_transactions.offset(offset).limit(limit).no_timeout.each do |transaction|
              next if check_if_transaction_transmission_exists?(transaction, transmission)

              new_transaction = clone_subject_and_create_transaction(transaction)
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

        def build_and_persist_xml(prior_transmission)
          ::Fdsh::H36::Request::BuildAndPersistH36Xml.new.call({ transmission: prior_transmission,
                                                                 assistance_year: @assistance_year,
                                                                 month: @month })
        end
      end
    end
  end
end
