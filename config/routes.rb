Spree::Core::Engine.routes.draw do

  namespace :admin do
    resources :fishbowl_logs, :except => [ :update ]

    resources :orders do
      member do
        put :fishbowl
        get :fishbowl
      end

      resources :shipments do
        collection do
          put :fishbowl
          get :fishbowl
        end
      end
    end

    resources :products do
      member do
        put :fishbowl
        get :fishbowl
      end

      resources :variants do
        member do
          put :fishbowl
          get :fishbowl
        end
      end
    end
  end

end
