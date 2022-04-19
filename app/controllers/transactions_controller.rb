# frozen_string_literal: true

# Transactions controller
class TransactionsController < ApplicationController

  def index
    @transactions = Kaminari.paginate_array(Transaction.where(:activities.nin => [nil, []]).map {|t| t.activities.map{|a| {a: a, t: t}}}.flatten).page params[:page]
  end

  def show
    @transaction = Transaction.find(params[:id])
  end
end
