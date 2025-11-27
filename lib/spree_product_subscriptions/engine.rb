module SpreeProductSubscriptions
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_product_subscriptions'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')).sort.each do |decorator|
        if defined?(Rails.autoloaders) && Rails.autoloaders.respond_to?(:main)
          Rails.autoloaders.main.ignore(decorator)
        end

        require_dependency(decorator)
      end
    end

    config.to_prepare { SpreeProductSubscriptions::Engine.activate }
  end
end
