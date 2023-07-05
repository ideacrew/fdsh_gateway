# frozen_string_literal: true

module Transmittable
  # Transmittable Transactions controller
  class TransactionsController < ApplicationController

    def show
      @transaction = Transmittable::Transaction.find(params[:id])
    end

    def index
      @transactions = Transmittable::Transaction.newest.page params[:page]
    end

  end
end