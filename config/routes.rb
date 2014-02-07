Giv2givRails::Application.routes.draw do

  mount StripeEvent::Engine => '/stripe'
  match '/dwolla' => 'dwolla#receive_hook', :via => :post

  scope :format => true, :constraints => { :format => /json/ } do
    namespace :api do

      post 'sessions/destroy' => 'sessions#destroy'
      post 'sessions/create' => 'sessions#create'
      post 'sessions/ping' => 'sessions#ping'

      resource :donors, :except => [:new, :edit, :destroy] do
        get 'balance_information', :on => :member
        get 'subscriptions', :on => :member
        get 'donations', :on => :member
        post 'forgot_password', :on => :member
        get "reset_password", :on => :member
        
        resources :payment_accounts, :except => [:new, :edit] do
          post 'donate_subscription', :on => :member
          get 'donation_list', :on => :member
          get 'all_donation_list', :on => :collection
          post 'one_time_payment', :on => :member
          get 'cancel_subscription', :on => :member
          get 'cancel_all_subscription', :on => :collection
        end
      end

      resources :endowment, :except => [:new, :edit, :destroy] do
        post 'add_charity', :on => :member
        delete 'remove_charity', :on => :member
        post 'rename_endowment', :on => :member
      end

      resources :charity, :except => [:new, :edit, :destroy, :update, :create] do
        #
      end

      resources :wishes, :except => [:new, :edit, :destroy, :update] do
        get 'random', :on => :collection
      end

      resources :balances, :except => [:new, :edit, :destroy, :create, :update, :show, :index] do
        get 'show_grants', :on => :collection
        post 'approve_donor_grants', :on => :collection
        post 'deny_grant', :on => :member
      end

    end # end namespace api
  end # end json scope

end
