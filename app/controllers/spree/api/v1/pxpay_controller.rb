require 'offsite_payments'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Pxpay

      #def self.token_url
      #  production_url = 'https://sec.paymentexpress.com/pxpay/pxaccess.aspx'
      #  uat_url = 'https://uat.paymentexpress.com/pxaccess/pxpay.aspx'
      #  ENV['RAILS_ENV'] == 'production' ? production_url : uat_url
      #end

      class Helper
        # it's a copy of upstream with some extensions
        def initialize(order, account, options = {})
          @token_parameters = {
              'PxPayUserId'       => account,
              'PxPayKey'          => options[:credential2],
              'CurrencyInput'     => options[:currency],
              'MerchantReference' => order,
              'EmailAddress'      => options[:customer_email],
              'TxnData1'          => options[:custom1],
              'TxnData2'          => options[:custom2],
              'TxnData3'          => options[:custom3],
              'AmountInput'       => "%.2f" % options[:amount].to_f.round(2),
              'EnableAddBillCard' => '0',
              'TxnType'           => 'Purchase',
              'UrlSuccess'        => options[:return_url],
              'UrlFail'           => options[:return_url],
              # add callback URL to PxPay form url request params
              'UrlCallback'       => options[:notify_url]
          }
          @redirect_parameters = {}

          super

          raise ArgumentError, "error - must specify return_url"        if token_parameters['UrlSuccess'].blank?
          raise ArgumentError, "error - must specify cancel_return_url" if token_parameters['UrlFail'].blank?

          # also add checks for required fields
          raise ArgumentError, "error - must specify pxpay_user_id"     if token_parameters['PxPayUserId'].blank?
          raise ArgumentError, "error - must specify pxpay_key"         if token_parameters['PxPayKey'].blank?
          raise ArgumentError, "error - must specify amount"            if token_parameters['AmountInput'].blank?
          raise ArgumentError, "error - must specify currency"          if token_parameters['CurrencyInput'].blank?
        end
      end
    end
  end
end



module Spree
  module Api
    module V1
      class PxpayController < Spree::Api::BaseController
        def create
          # uncomment to log http requests
          #require 'httplog'

          order = Spree::Order.find_by(number: params[:merchant_ref])
          #render json: order
          logger = Rails.logger
          logger.info "Order? #{order}"
          logger.info "Order? #{order[:number]}_#{Time.now.to_i.to_s}"

          transaction_id = order[:number] + "_" + Time.now.to_i.to_s

          pxpay_helper = ::OffsitePayments::Integrations::Pxpay::Helper.new(
              transaction_id,
              SpreePxpay::CONFIG[:pxpay_user_id],
              credential2: SpreePxpay::CONFIG[:pxpay_key],
              return_url: params[:return_url],
              notify_url: params[:callback_url],
              amount: order[:total],
              currency: order[:currency]
          )

          hpp_form_url = pxpay_helper.credential_based_url

          Spree::PxpayCheckout.create(
              transaction_id: transaction_id,
              state: "Created",
          )

          render json: hpp_form_url
        end
      end
    end
  end
end
