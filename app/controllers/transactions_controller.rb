# frozen_string_literal: true

# Transactions controller
class TransactionsController < ApplicationController

  def index
    @search = params.fetch(:search) unless params[:search].blank?
    page_no = params[:page] ? params[:page].to_i : 1
    query_results = Queries::TransactionsIndexPageQuery.new.call(@search, page: page_no)
    @results = query_results[:results]
    redirect_to transaction_path(@results.first[:_id]) if query_results[:count] == 1
    @transactions = Kaminari.paginate_array(query_results[:results].to_a, total_count: query_results[:count]).page(params[:page])
  end

  def show
    @transaction = Transaction.find(params[:id])
  end
end
