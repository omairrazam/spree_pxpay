Spree::Payment.class_eval do
  def transaction_id
    if payment_method.is_a? Spree::Gateway::PxpayGateway
      source.transaction_id
    else
      response_code
    end
  end

  def build_source
    logger = Rails.logger
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")
    logger.info("Building source")

    return unless new_record?

    logger.info("Really building source")

    logger.info source_attributes.present?
    logger.info source.blank?
    #logger.info payment_method.try(:payment_source_class)

    if source_attributes.present? && source.blank? && payment_method.try(:payment_source_class)
      self.source = payment_method.payment_source_class.new(source_attributes)
      source.payment_method_id = payment_method.id
      source.user_id = order.user_id if order
    end

    #if payment_method.is_a? Spree::Gateway::PxpayGateway && source.blank?
    logger.info("Really building source2")
    logger.info(order.completed?.to_s)

    self.source = payment_method.payment_source_class.new
    #source.payment_method_id = payment_method.id
    #source.user_id = order.user_id if order

    # Spree will not process payments if order is completed.
    # We should call process! for completed orders to create a new Mollie payment.
    process! if order.completed?
    #end
  end
end
