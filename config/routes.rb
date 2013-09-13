

Giv2givRails::Application.routes.draw do

  scope :format => true, :constraints => { :format => /json/ } do
    namespace :api do

      mount StripeEvent::Engine => '/stripe_webhook' # should make stripe webhooks available at /api/stripe_webhook

      post 'sessions/destroy' => 'sessions#destroy'
      post 'sessions/create' => 'sessions#create'

      resource :donors, :except => [:new, :edit, :destroy] do
        resources :payment_accounts, :except => [:new, :edit] do
          post 'donate', :on => :member
        end
      end

      resources :charity_group, :except => [:new, :edit, :destroy] do
        post 'add_charity', :on => :member
        post 'rename_charity_group', :on => :member
      end

#      resources :charity_group, :except => [:new, :edit, :destroy] do
#        post 'rename_charity_group', :on => :member
#      end

      resources :charity, :except => [:new, :edit, :destroy, :update, :create] do
        get 'search', :on => :collection
      end
    end # end namespace api
  end # end json scope

end
