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
    @transactions = if @search
                      Kaminari.paginate_array(@results.map {|t| t.activities.map {|a| { a: a, t: t }}}.flatten).page params[:page]
                    else
                      Kaminari.paginate_array(Transaction.where(:activities.nin => [nil, []]).map do |t|
                                                t.activities.map do |a|
                                                  { a: a, t: t }
                                                end
                                              end.flatten).page params[:page]
                    end
  end

  def show
    @transaction = Transaction.find(params[:id])
  end
end
