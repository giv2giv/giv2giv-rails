Giv2givRails::Application.routes.draw do
  
  scope :format => true, :constraints => { :format => /json/ } do
    namespace :api do

      mount StripeEvent::Engine => '/stripe_webhook' # should make stripe webhooks available at /api/stripe_webhook

      post 'sessions/destroy' => 'sessions#destroy'
      post 'sessions/create' => 'sessions#create'

      resource :donors, :except => [:new, :edit, :destroy] do
        resources :payment_accounts, :except => [:new, :edit] do
          post 'donate_subscription', :on => :member
          get 'donation_list', :on => :member
          post 'one_time_payment', :on => :collection
          get 'all_donation_list', :on => :collection
          get 'cancel_subscription', :on => :member
          get 'cancel_all_subscription', :on => :collection
        end
      end

      resources :charity_group, :except => [:new, :edit, :destroy] do
        post 'add_charity', :on => :member
        delete 'remove_charity', :on => :member
        post 'rename_charity_group', :on => :member
      end

      resources :charity, :except => [:new, :edit, :destroy, :update, :create] do
        #
      end

      resources :balances, :except => [:new, :edit, :destroy, :create, :update, :show, :index] do
        get 'show_grants', :on => :collection
      end

    end # end namespace api
  end # end json scope

end
