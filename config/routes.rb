Giv2givRails::Application.routes.draw do

  mount StripeEvent::Engine => '/stripe'
  match '/dwolla' => 'dwolla#receive_hook', :via => :post

  get '/auth/:provider/callback' => 'api/sessions#omniauth_callback'

  get '/signout', to: 'sessions#destroy', as: 'signout'
  get '/auth/failure', to: redirect('/')
  
  #get '/dwolla/start' => 'api/sessions#dwolla_start'
  #get '/dwolla/finish' => 'api/sessions#dwolla_finish'

  scope :format => true, :constraints => { :format => /json/ } do

    namespace :api do

      post 'sessions/destroy' => 'sessions#destroy'
      post 'sessions/create' => 'sessions#create'
      post 'sessions/ping' => 'sessions#ping'
      post 'sessions/create_facebook' => 'sessions#create_facebook'

      resource :donors, :except => [:new, :edit, :destroy] do
        get 'balance_information', :on => :member
        get 'subscriptions', :on => :member
        get 'donations', :on => :member
        post 'forgot_password', :on => :member
        post 'reset_password', :on => :member
        post 'send_invite', :on => :member
        post 'subscribe', :on => :collection
        post 'unsubscribe', :on => :collection
        
        resources :payment_accounts, :except => [:new, :edit] do        
          post 'donate_subscription', :on => :member
          get 'donation_list', :on => :member
          post 'one_time_payment', :on => :member
          get 'cancel_subscription', :on => :member
          get 'all_donation_list', :on => :collection
          post 'verify_knox', :on => :collection
          #get 'cancel_all_subscription', :on => :collection #development stage
        end
      end

      resources :endowment, :except => [:new, :edit, :destroy] do
        post 'add_charity', :on => :member
        delete 'remove_charity', :on => :member
        post 'rename_endowment', :on => :member
        #post 'anonymous_donation', :on => :member
        get 'widget_data', :on => :member
        get 'autocomplete', :on=>:collection
        get 'my_endowments', :on=>:collection
        get 'trending', :on=>:collection
        get 'near', :on=>:collection
        get 'find_by_slug', :on=> :collection
      end

      resources :charity, :except => [:new, :edit, :destroy, :update, :create] do
        get 'show_endowments', :on => :member
        get 'near', :on=> :collection
        get 'find_by_slug', :on=> :collection
        get 'widget_data', :on => :member
        get 'stripe', :on => :member
        get 'dwolla', :on => :member
        get 'dwolla_done', :on => :member
        get 'autocomplete', :on=> :collection
      end

      resources :wishes, :except => [:new, :edit, :destroy, :update] do
        get 'random', :on => :collection
      end

      resources :balances, :except => [:new, :edit, :destroy, :create, :update, :show, :index] do
        get 'show_grants', :on => :collection #admin-only
        post 'deny_grant', :on => :member #admin-only        
      end

    end # end namespace api
  end # end json scope

end
