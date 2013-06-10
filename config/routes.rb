Giv2givRails::Application.routes.draw do

  namespace :api do
    post 'sessions/destroy' => 'sessions#destroy'
    post 'sessions/create' => 'sessions#create'
  end

end
