Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "migrations#index"

  resources :patients, only: [ :index, :show ]
  resources :migrations, only: [ :index, :show, :new, :create ]
end
