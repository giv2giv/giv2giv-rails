Giv2givRails::Application.routes.draw do

  scope :format => true, :constraints => { :format => /json/ } do
    namespace :api do
      post 'sessions/destroy' => 'sessions#destroy'
      post 'sessions/create' => 'sessions#create'

      resource :donors, :except => [:new, :edit, :destroy] do
        resources :payment_accounts, :except => [:new, :edit]
      end
    end
  end # end scope

end
