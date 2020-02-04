module Spree
  class PxpayController < BaseController
    skip_before_action :verify_authenticity_token, only: [:update_payment_status]

    # Pxpay sends us information about a transaction through the webhook.
    # We should update the payment state accordingly.
    def update_payment_status
      logger = Rails.logger
      logger.info "Webhook called for PxPay transaction #{params[:result]}"

      # test with ?result=00001100957328720b8069497ee91383

      pxpay = Spree::PaymentMethod.find_by_type 'Spree::Gateway::PxpayGateway'
      pxpay.update_payment_status params[:result]

      head :ok
    end
  end
end

