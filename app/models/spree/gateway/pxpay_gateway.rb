module Spree
  class Gateway::PxpayGateway < PaymentMethod
    require 'http'
    require 'json'

    preference :pxpay_user_id, :string
    preference :pxpay_key, :string

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
      logger.info("#{money.to_json}")
      logger.info("#{source.to_json}")
      logger.info("#{gateway_options.to_json}")

      begin
        # First of all, invalidate all previous Mollie orders to prevent multiple paid orders
        #invalidate_previous_orders(gateway_options[:order].id)

        # Create a new Mollie order and update the payment source
        #order_params = prepare_order_params(money, source, gateway_options)
        #mollie_order = ::Mollie::Order.create(order_params)
        #MollieLogger.debug("Mollie order #{mollie_order.id} created for Spree order #{gateway_options[:order_id]}")
        #
        #

        order = Spree::Order(gateway_options[:order_id])
        logger.info "Order? #{order}"
        logger.info "Order? #{order[:number]}_#{Time.now.to_i.to_s}"

        transaction_id = order[:number] + "_" + Time.now.to_i.to_s

        # TODO: Move to ::Pxpay::Transaction class
        pxpay_helper = ::OffsitePayments::Integrations::Pxpay::Helper.new(
            transaction_id,
            SpreePxpay::CONFIG[:pxpay_user_id],
            credential2: SpreePxpay::CONFIG[:pxpay_key],
            return_url: params[:return_url],
            notify_url: params[:callback_url],
            amount: order[:total],
            currency: order[:currency]
        )

        source.status = "Created"
        #source.payment_id = mollie_order.id
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

      #data = {
      #    PxPayUserId: get_preference(:pxpay_user_id),
      #    PxPayKey: get_preference(:pxpay_key),
      #    Response: transaction_details_key,
      #}.to_xml root: "ProcessResponse"
      #response = HTTP.post('https://sec.paymentexpress.com/pxaccess/pxpay.aspx', :body => data)
      #pxpay_response = Hash.from_xml response.body.to_s

      pxpay_response = Hash.from_xml("<Response valid=\"1\"><AmountSettlement>599.00</AmountSettlement><TotalAmount></TotalAmount><AmountSurcharge></AmountSurcharge><AuthCode></AuthCode><CardName>Visa</CardName><CardNumber>411111........11</CardNumber><DateExpiry>0220</DateExpiry><DpsTxnRef>0000000b61196b00</DpsTxnRef><SurchargeDpsTxnRef></SurchargeDpsTxnRef><Success>0</Success><ResponseText>DECLINED</ResponseText><DpsBillingId></DpsBillingId><CardHolderName>DEED DD</CardHolderName><CurrencySettlement>USD</CurrencySettlement><TxnData1></TxnData1><TxnData2></TxnData2><TxnData3></TxnData3><TxnType>Purchase</TxnType><CurrencyInput>USD</CurrencyInput><MerchantReference>R540857103_1580771044</MerchantReference><ClientInfo>222.154.231.98</ClientInfo><TxnId>P114119C93D209C7</TxnId><EmailAddress></EmailAddress><BillingId></BillingId><TxnMac>2BC20210</TxnMac><CardNumber2>1110200000000019</CardNumber2><DateSettlement>19800101</DateSettlement><IssuerCountryId>0</IssuerCountryId><IssuerCountryCode></IssuerCountryCode><Cvc2ResultCode>NotUsed</Cvc2ResultCode><ReCo>BH</ReCo><ProductSku></ProductSku><ShippingName></ShippingName><ShippingAddress></ShippingAddress><ShippingPostalCode></ShippingPostalCode><ShippingPhoneNumber></ShippingPhoneNumber><ShippingMethod></ShippingMethod><BillingName></BillingName><BillingPostalCode></BillingPostalCode><BillingAddress></BillingAddress><BillingPhoneNumber></BillingPhoneNumber><PhoneNumber></PhoneNumber><AccountInfo></AccountInfo></Response>")

      if pxpay_response["Response"]["valid"] == '1'
        transaction_id = pxpay_response["Response"]["MerchantReference"]
        checkout = Spree::PxpayCheckout.find_or_initialize_by(transaction_id: transaction_id)
        logger.info "PxPay webhook called2"

        #if !checkout
        #  checkout = Spree::PxpayCheckout.new
        #  checkout.transaction_id = transaction_id
        #end
        #logger.info "PxPay webhook called3"

        if pxpay_response["Response"]["Success"] == "0"
          # TODO: Trigger order update
          #  should be checkout.order.finalize!
          logger.info "Here"
          order_number, transaction_time = transaction_id.to_s.split('_')
          logger.info "There"
          order = Spree::Order.find_by(number: order_number)
          logger.info "somewhere"
          logger.info order.number
          checkout.payments.first.complete!
          #order.finalize!
          #order.update_attributes(state: 'complete', completed_at: Time.now)
          checkout.state = "Processed"
        else
          logger.info "Yeah"
          checkout.state = "Failed"
        end

        logger.info "PxPay webhook called4"
        checkout.save
      else
        # TODO: Maybe tell Windcave that we don't understand the transaction response? They will
        #  retry the callback URL six times if we return anything other than 200 or 404.
      end
    end
  end
end
