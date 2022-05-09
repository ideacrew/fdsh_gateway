# frozen_string_literal: true

# Transactions controller
class TransactionsController < ApplicationController

  def index
    if params.key?(:search)
      search_id = params.fetch(:search)
      @search = search_id unless search_id.blank?
      @results = Transaction.or({ correlation_id: /#{search_id}/ }, { application_id: /#{search_id}/ },
                                { primary_hbx_id: /#{search_id}/ }).and(:activities.nin => [nil, []])
      redirect_to @results.first if @results&.length == 1
    end

    arr = @search ? @results : Transaction.where(:activities.nin => [nil, []])
    sorted_arr = arr.map {|t| t.activities.map {|a| { a: a, t: t }}}.flatten.sort_by {|activity| activity[:a].updated_at}.reverse!
    @transactions = Kaminari.paginate_array(sorted_arr).page params[:page]
  end

  def show
    @transaction = Transaction.find(params[:id])
  end
end
