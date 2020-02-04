class CreateSpreePxpayPaymentSources < SpreeExtension::Migration[4.2]
  def change
    create_table :spree_pxpay_payment_sources do |t|
      t.string :payment_id, index: true
      t.string :status, index: true
      t.string :payment_url
    end
  end
end
