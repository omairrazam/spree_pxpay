Spree::Core::Engine.add_routes do
  resource :pxpay, only: [], controller: :pxpay do
    get 'transaction_callback/', action: :update_payment_status, as: 'pxpay_update_payment_status'
  end
  
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      # Our new route goes here!
      resources :pxpay, only: [:create]
    end
  end
end
