module Spree::Pxpay; end
module SpreePxpay
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_pxpay'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "spree.pxpay.preferences", :before => :load_config_initializers do |app|
      Spree::Pxpay::Config = Spree::PxpayConfiguration.new
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      ::Rails.application.config.spree.payment_methods << Spree::Gateway::PxpayGateway
      Spree::PermittedAttributes.source_attributes << :return_url
      Spree::Api::ApiHelpers.payment_source_attributes << :return_url
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
