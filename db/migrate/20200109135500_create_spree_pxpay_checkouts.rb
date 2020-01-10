class CreateSpreePxpayCheckouts < SpreeExtension::Migration[4.2]
  def change
    create_table :spree_pxpay_checkouts do |t|
      t.string :transaction_id, index: true
      t.string :state, index: true
      t.string :token
      t.string :created_at
    end
  end
end
