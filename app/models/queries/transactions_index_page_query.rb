# frozen_string_literal: true

module Queries
  # Query for Transactions index page (FDSH home page)
  class TransactionsIndexPageQuery

    def call(search_id = nil, page:)
      @page = page
      @search_id = search_id
      @default_per_page = Kaminari.config.default_per_page
      { results: query, count: transaction_counter }
    end

    def transaction_counter
      count_aggregate = [unwind_stage, count_stage]
      count_aggregate.prepend(match_stage) unless @search_id.blank?
      Transaction.collection.aggregate(count_aggregate).first&.dig("grand_total")
    end

    def skip_val
      (@page - 1) * @default_per_page
    end

    def search_criteria
      escaped_id = /#{Regexp.escape(@search_id)}/ # escape special characters in encrypted strings
      { '$or' => [{ correlation_id: escaped_id }, { application_id: escaped_id }, { primary_hbx_id: escaped_id }] }
    end

    def query
      stages = [unwind_stage, sort_stage, skip_stage, limit_stage]
      stages.prepend(match_stage) unless @search_id.blank?
      Transaction.collection.aggregate(stages).allow_disk_use(true)
    end

    def count_stage
      { '$count' => 'grand_total' }
    end

    def match_stage
      { '$match' => search_criteria }
    end

    def unwind_stage
      { '$unwind' => { "path" => "$activities", "preserveNullAndEmptyArrays" => true } }
    end

    def sort_stage
      { '$sort' => { 'activities.updated_at' => -1, 'correlation_id' => 1 } }
    end

    def skip_stage
      { '$skip' => skip_val }
    end

    def project_stage
      { '$project' => { 'activities' => filter_stage } }
    end

    def limit_stage
      { '$limit' => @default_per_page }
    end

  end
end