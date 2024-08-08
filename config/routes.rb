Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  resources :tables
  resources :authors do
    get "edit"
  end
  resources :sales do
    get "edit"
  end
  resources :reviews do
    get "edit"
  end
  resources :books do
    get "edit"
  end
end
