# frozen_string_literal: true

Rails.application.routes.draw do

  devise_for :users, skip: [:registrations]
  devise_scope :user do
    get 'users/edit' => 'devise/registrations#edit', as: 'edit_user_registration'
    put 'users' => 'devise/registrations#update', as: 'user_registration'
  end

  root 'activity_row#index'

  resources :transactions, only: [:show]

  namespace :transmittable do
    resources :jobs, only: [:index, :show]
    resources :transactions, only: [:index, :show]
  end

  resources :registries, only: [:index]
  get '/connectivity_tests/oauth', to: 'connectivity_tests#oauth'

end
