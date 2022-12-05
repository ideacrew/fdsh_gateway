# frozen_string_literal: true

# ActivityRow controller
class ActivityRowController < ApplicationController

  def index
    if params.key?(:search)
      search_value = params.fetch(:search)
      @search = search_value unless search_value.blank?
      @search_results = ActivityRow.or({ primary_hbx_id: search_value }, { application_id: search_value })
    end
    results = @search ? @search_results : ActivityRow.all
    @activity_rows = results.page params[:page]
  end

end
