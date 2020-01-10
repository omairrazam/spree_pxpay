module SpreePxpay
  CONFIG={}
  def self.config
    yield CONFIG if block_given?
  end
end

