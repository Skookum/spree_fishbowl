Spree::Core::Engine.routes.draw do

  namespace :admin do
    resources :fishbowl_logs, :except => [ :update ]
  end

end
