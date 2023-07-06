# frozen_string_literal: true

module Transmittable
  # Transmittable Jobs controller
  class JobsController < ApplicationController

    def show
      @job = Transmittable::Job.find(params[:id])
    end

    def index
      @jobs = Transmittable::Job.newest.page params[:page]
    end

  end
end