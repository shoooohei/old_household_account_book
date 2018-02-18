Rails.application.routes.draw do
  resources :sessions, only: [:new, :create, :destroy]

  resources :users
  resources :expenses do
    collection do
      get :both
    end
  end
  resources :categories
  resources :badgets
  root to: "expenses#both"
end
