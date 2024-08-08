Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "authors#index"

  resources :tables
  resources :authors do
    get "edit"
    get "author_summary", on: :collection
  end

  resources :sales do
    get "edit"
  end

  resources :reviews do
    get "edit"
  end

  resources :books do
    get "edit"
    get "top_rated", on: :collection
    get "top_selling", on: :collection
    get "search", on: :collection
  end

end
