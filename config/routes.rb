Rails.application.routes.draw do
  resources :tasks , defaults: {format: 'json'} do
    collection do
      get :stats, to: "tasks#stats", defaults: {format: 'json'}
    end
    member do
      post :status, to: "tasks#update_status", defaults: {format: 'json'}
      post :duplicate, to: "tasks#duplicate", defaults: {format: 'json'}
    end
  end
  resources :genres
end
