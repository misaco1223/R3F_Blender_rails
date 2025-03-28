Rails.application.routes.draw do
  namespace :api do
    resources :cut_cubes, only: [:create, :index, :show, :destroy, :update]
    resources :cookies, only: [:create, :index]
    resources :users, only: [:create]
    resource :sessions, only: [:create, :destroy]
    resources :bookmarks, only: [:create, :index, :destroy]
  end

  get '*path', to: 'application#frontend', constraints: ->(req) {!req.xhr? && req.format.html?}
end
