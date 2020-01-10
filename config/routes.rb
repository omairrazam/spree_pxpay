Spree::Core::Engine.add_routes do
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      # Our new route goes here!
      resources :pxpay, only: [:create]
    end
  end
end
