module Spree::PaymentDecorator
  # Makes Zeitwerk happy
end

Spree::Payment.class_eval do
  def transaction_id
    if payment_method.is_a? Spree::Gateway::PxpayGateway
      source.transaction_id
    else
      response_code
    end
  end

  def build_source
    return unless new_record?
    logger = Rails.logger
    logger.info("Building source")

    # START Original handler
    #if source_attributes.present? && source.blank? && payment_method.try(:payment_source_class)
    #  self.source = payment_method.payment_source_class.new(source_attributes)
    #  source.payment_method_id = payment_method.id
    #  source.user_id = order.user_id if order
    #end
    # END Original handler

    if source_attributes.present? && source.blank? && payment_method.try(:payment_source_class)
      # Sets the return URL from the incoming request parameters
      self.source = payment_method.payment_source_class.new(source_attributes)

      # Spree will not process payments if order is completed.
      # We should call process! for completed orders to create a new PxPay payment.
      process! if order.completed?
    end
  end
end
