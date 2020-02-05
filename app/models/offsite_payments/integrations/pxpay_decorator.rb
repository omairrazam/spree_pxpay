require 'offsite_payments'

module OffsitePayments::Integrations::PxpayDecorator
  # Makes Zeitwerk happy
end

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Pxpay
      class Helper
        # it's a copy of upstream with some extensions, we need to specify URL callback
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
