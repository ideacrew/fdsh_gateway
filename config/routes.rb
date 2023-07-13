# frozen_string_literal: true

Rails.application.routes.draw do

  devise_for :users

  root 'activity_row#index'

  resources :transactions, only: [:show]

  get '/connectivity_tests/oauth', to: 'connectivity_tests#oauth'

end
