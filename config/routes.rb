# frozen_string_literal: true

Rails.application.routes.draw do

  devise_for :users

  root 'activity_row#index'

  resources :transactions, only: [:show]

  namespace :transmittable do
    resources :jobs, only: [:index, :show]
  end

end
