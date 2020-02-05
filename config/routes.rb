Spree::Core::Engine.add_routes do
  resource :pxpay, only: [], controller: :pxpay do
    get 'transaction_callback/', action: :update_payment_status, as: 'pxpay_update_payment_status'
  end
end
