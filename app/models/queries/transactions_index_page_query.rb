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
      # escaped_id = /#{@search_id}/ # escape special characters in encrypted strings
      { '$or' => [{ correlation_id: escaped_id }, { application_id: escaped_id }, { primary_hbx_id: escaped_id }] }
    end

    def query
      stages = [unwind_stage, sort_stage, skip_stage, limit_stage]
      stages << match_stage unless @search_id.blank?
      Transaction.collection.aggregate(stages).allow_disk_use(true)
    end

    def activities_present
      { 'activities' => { '$nin' => [nil, []] } }
    end

    def match_stage
      match_criteria = activities_present
      match_criteria.merge!(search_criteria)
      { '$match' => match_criteria }
    end

    def unwind_stage
      { '$unwind' => '$activities' }
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