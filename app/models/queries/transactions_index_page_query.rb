# frozen_string_literal: true

module Queries
  # Query for Transactions index page (FDSH home page)
  class TransactionsIndexPageQuery

    def call(search_id = nil, page:)
      @page = page
      @search_id = search_id
      @default_per_page = Kaminari.config.default_per_page
      query
    end

    def skip_val
      (@page - 1) * @default_per_page
    end

    def search_criteria
      escaped_id = /#{Regexp.escape(@search_id)}/ # escape special characters in encrypted strings
      { '$or' => [{ correlation_id: /#{escaped_id}/ }, { application_id: /#{escaped_id}/ }, { primary_hbx_id: /#{escaped_id}/ }] }
    end

    def query
      stages = [match_stage, sort_stage, facet_stage]
      Transaction.collection.aggregate(stages)
    end

    def activities_present
      { 'activities' => { '$nin' => [nil, []] } }
    end

    def match_stage
      match_criteria = activities_present
      match_criteria.merge!(search_criteria) if @search_id
      { '$match' => match_criteria }
    end

    def unwind_stage
      { '$unwind' => '$activities' }
    end

    def sort_stage
      { '$sort' => { 'activity.updated_at' => -1, 'correlation_id' => 1 } }
    end

    def facet_stage
      { '$facet' => {
        'metadata' => [{ '$count' => 'total' }],
        'data' => [skip_stage, project_stage, unwind_stage, limit_stage, facet_sort_stage]
      } }
    end

    def skip_stage
      { '$skip' => skip_val }
    end

    def project_stage
      { '$project' => { 'activities' => filter_stage } }
    end

    def filter_stage
      { '$filter' => {
        'input' => '$activities',
        'as' => 'activity',
        'cond' => { '$eq' => ["$$activity.updated_at", { '$max' => "$activities.updated_at" }] }
      } }
    end

    def limit_stage
      { '$limit' => @default_per_page }
    end

    def facet_sort_stage
      { '$sort' => { 'activities.updated_at' => -1, 'correlation_id' => 1 } }
    end
  end
end