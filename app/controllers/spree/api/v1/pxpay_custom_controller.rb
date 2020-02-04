require 'offsite_payments'

module Spree
  module Api
    module V1
      class PxpayCustomController < Spree::Api::BaseController
        def create
          # uncomment to log http requests
          #require 'httplog'

          order = Spree::Order.where(channel: params[:merchant_ref])

          # TODO: We should get merchant reference and charge amounts from existing Orders
          pxpay_helper = ::OffsitePayments::Integrations::Pxpay::Helper.new(
              params[:merchant_ref],
              SpreePxpay::CONFIG[:pxpay_user_id],
              credential2: SpreePxpay::CONFIG[:pxpay_key],
              return_url: params[:return_url],
              notify_url: params[:callback_url],
              amount: params[:amount],
              currency: params[:currency]
          )

          #hpp_form_url = pxpay_helper.credential_based_url

          render json: order
        end
      end
    end
  end
end
