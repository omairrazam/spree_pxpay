Spree::Payment::Processing.module_eval do
  def process!(_amount = nil)
    logger = Rails.logger
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    logger.info("About to create payment")
    if payment_method.is_a? Spree::Gateway::PxpayGateway
      process_with_pxpay
    else
      process_with_spree
    end
  end

  def process_with_spree
    if payment_method && payment_method.auto_capture?
      purchase!
    else
      authorize!
    end
  end

  def process_with_pxpay
    amount ||= money.money
    started_processing!
    response = payment_method.process(
      amount,
      source,
      gateway_options
    )
    handle_response(response, :started_processing, :failure)
  end
end
