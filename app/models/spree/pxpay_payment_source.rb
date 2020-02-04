module Spree
  class PxpayPaymentSource < Spree::Base
    belongs_to :payment_method
    has_many :payments, as: :source

    def transaction_id
      payment_id
    end
  end
end