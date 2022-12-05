# frozen_string_literal: true

# ActivityRow controller
class ActivityRowController < ApplicationController

def index
    if params.key?(:search)
      search_value = params.fetch(:search)
      @search = search_value unless search_value.blank?
      @search_results = ActivityRow.or({ primary_hbx_id: search_value }, { application_id: search_value })
    end

    arr = @search ? @search_results : ActivityRow.all

    sorted_arr = arr.sort_by(&:updated_at).reverse!

    @activity_rows = Kaminari.paginate_array(sorted_arr).page params[:page]
  end

end
