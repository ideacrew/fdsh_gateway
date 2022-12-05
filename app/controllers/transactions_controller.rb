# frozen_string_literal: true

# Transactions controller
class TransactionsController < ApplicationController

  def show
    @transaction = Transaction.find(params[:id])
  end

end