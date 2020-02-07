module Spree
  class Gateway::PxpayGateway < PaymentMethod
    require 'http'
    require 'json'
    require 'offsite_payments'

    preference :pxpay_user_id, :string
    preference :pxpay_key, :string
    preference :callback_hostname, :string

    has_many :spree_pxpay_payment_sources, class_name: 'Spree::PxpayPaymentSource'

    def payment_source_class
      Spree::PxpayPaymentSource
    end

    def provider_class
      ::OffsitePayments::Integrations::Pxpay::Helper
    end

    def auto_capture?
      true
    end

    def source_required?
      true
    end

    def available_for_order?(_order)
      true
    end

    def gateways(options = {})
      logger = Rails.logger
      logger.info("Gateways was called #{options.to_json.to_s}")
    end

    # Create PxPay transaction
    def process(money, source, gateway_options)
      logger = Rails.logger
      logger.info("About to create payment for order #{gateway_options[:order_id]}")

      begin
        # TODO: Figure out if we need to do that:
        # First of all, invalidate all previous Mollie orders to prevent multiple paid orders
        #invalidate_previous_orders(gateway_options[:order].id)

        order = gateway_options[:order]
        payment_number = gateway_options[:order_id].split('-')[1]
        payment = Spree::Payment.find_by_number(payment_number)

        # TODO: Move to a new ::Pxpay::Transaction class
        pxpay_helper = ::OffsitePayments::Integrations::Pxpay::Helper.new(
            gateway_options[:order_id],
            SpreePxpay::CONFIG[:pxpay_user_id],
            credential2: SpreePxpay::CONFIG[:pxpay_key],
            return_url: source[:return_url],
            notify_url: "https://#{SpreePxpay::CONFIG[:callback_hostname]}/pxpay/transaction_callback",
            amount: order[:total],
            currency: order[:currency]
        )

        source.status = "Created"
        source.payment_id = payment.id
        source.payment_url = pxpay_helper.credential_based_url
        source.save!
        ActiveMerchant::Billing::Response.new(true, 'Order created')
      rescue Exception => e
        logger.error("Could not create payment for order #{gateway_options[:order_id]}: #{e.message}")
        ActiveMerchant::Billing::Response.new(false, "Order could not be created: #{e.message}")
      end
    end

    def update_payment_status(transaction_details_key)
      logger = Rails.logger
      logger.info "PxPay webhook called"

      # TODO: Use OffsitePayments helper here?
      data = {
          PxPayUserId: get_preference(:pxpay_user_id),
          PxPayKey: get_preference(:pxpay_key),
          Response: transaction_details_key,
      }.to_xml root: "ProcessResponse"
      response = HTTP.post('https://sec.paymentexpress.com/pxaccess/pxpay.aspx', :body => data)
      pxpay_response = Hash.from_xml response.body.to_s
      # Successful override
      #pxpay_response = Hash.from_xml "<Response valid=\"1\"><AmountSettlement>599.00</AmountSettlement><TotalAmount></TotalAmount><AmountSurcharge></AmountSurcharge><AuthCode>151306</AuthCode><CardName>Visa</CardName><CardNumber>411111........11</CardNumber><DateExpiry>0220</DateExpiry><DpsTxnRef>0000000b6150d383</DpsTxnRef><SurchargeDpsTxnRef></SurchargeDpsTxnRef><Success>1</Success><ResponseText>APPROVED</ResponseText><DpsBillingId></DpsBillingId><CardHolderName>John Smith</CardHolderName><CurrencySettlement>NZD</CurrencySettlement><TxnData1></TxnData1><TxnData2></TxnData2><TxnData3></TxnData3><TxnType>Purchase</TxnType><CurrencyInput>NZD</CurrencyInput><MerchantReference>R540857103-P6V38V2C</MerchantReference><ClientInfo>222.154.231.98</ClientInfo><TxnId>P1142FD2D83516A1</TxnId><EmailAddress></EmailAddress><BillingId></BillingId><TxnMac>2BC20210</TxnMac><CardNumber2>1110200000000019</CardNumber2><DateSettlement>20200205</DateSettlement><IssuerCountryId>0</IssuerCountryId><IssuerCountryCode></IssuerCountryCode><Cvc2ResultCode>P</Cvc2ResultCode><ReCo>00</ReCo><ProductSku></ProductSku><ShippingName></ShippingName><ShippingAddress></ShippingAddress><ShippingPostalCode></ShippingPostalCode><ShippingPhoneNumber></ShippingPhoneNumber><ShippingMethod></ShippingMethod><BillingName></BillingName><BillingPostalCode></BillingPostalCode><BillingAddress></BillingAddress><BillingPhoneNumber></BillingPhoneNumber><PhoneNumber></PhoneNumber><AccountInfo></AccountInfo></Response>"
      # Failed override
      #pxpay_response = Hash.from_xml "<Response valid=\"1\"><AmountSettlement>599.00</AmountSettlement><TotalAmount></TotalAmount><AmountSurcharge></AmountSurcharge><AuthCode></AuthCode><CardName>Visa</CardName><CardNumber>411111........11</CardNumber><DateExpiry>0220</DateExpiry><DpsTxnRef>0000000b614d23a3</DpsTxnRef><SurchargeDpsTxnRef></SurchargeDpsTxnRef><Success>0</Success><ResponseText>DECLINED</ResponseText><DpsBillingId></DpsBillingId><CardHolderName>John Smith</CardHolderName><CurrencySettlement>NZD</CurrencySettlement><TxnData1></TxnData1><TxnData2></TxnData2><TxnData3></TxnData3><TxnType>Purchase</TxnType><CurrencyInput>USD</CurrencyInput><MerchantReference>R540857103-P1WXNKBA</MerchantReference><ClientInfo>222.154.231.98</ClientInfo><TxnId>P1142FA8C527E2F8</TxnId><EmailAddress></EmailAddress><BillingId></BillingId><TxnMac>2BC20210</TxnMac><CardNumber2>1110200000000019</CardNumber2><DateSettlement>19800101</DateSettlement><IssuerCountryId>0</IssuerCountryId><IssuerCountryCode></IssuerCountryCode><Cvc2ResultCode>NotUsed</Cvc2ResultCode><ReCo>BH</ReCo><ProductSku></ProductSku><ShippingName></ShippingName><ShippingAddress></ShippingAddress><ShippingPostalCode></ShippingPostalCode><ShippingPhoneNumber></ShippingPhoneNumber><ShippingMethod></ShippingMethod><BillingName></BillingName><BillingPostalCode></BillingPostalCode><BillingAddress></BillingAddress><BillingPhoneNumber></BillingPhoneNumber><PhoneNumber></PhoneNumber><AccountInfo></AccountInfo></Response>"

      if pxpay_response["Response"]["valid"] == '1'
        order_number, payment_number = pxpay_response["Response"]["MerchantReference"].to_s.split('-')
        payment = Spree::Payment.find_by_number(payment_number)

        if pxpay_response["Response"]["Success"] == "1"
          if payment.completed?
            logger.info 'Payment is already completed'
            return
          end
          payment.complete!

          if payment.order.completed?
            logger.info 'Order is already completed'
          else
            payment.order.finalize!
            payment.order.update_attributes(state: 'complete', completed_at: Time.now)
          end
          payment.source.status = "Processed"
        else
          logger.info 'Payment has failed'
          payment.response_code = pxpay_response["Response"]["ReCo"]
          payment.save!
          payment.source.status = "Failed"
        end

        payment.source.save!
      else
        # TODO: Maybe tell Windcave (ex. PaymentExpress) that we don't understand the transaction response? They will
        #  retry the callback URL six times if we return anything other than 200 or 404.
      end
    end
  end
end
