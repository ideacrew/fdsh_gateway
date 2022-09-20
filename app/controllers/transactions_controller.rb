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

    page_no = params[:page] ? params[:page].to_i : 1
    query_results = Queries::TransactionsIndexPageQuery.new.call(@search, page: page_no).first
    total_count = query_results&.dig('metadata')&.first&.dig('total')&.to_i
    @transactions = Kaminari.paginate_array(query_results['data'], total_count: total_count).page(params[:page])
  end

  def show
    @transaction = Transaction.find(params[:id])
  end
end
