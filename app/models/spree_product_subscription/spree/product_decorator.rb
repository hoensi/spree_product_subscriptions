module SpreeProductSubscription
  module Spree
    module ProductDecorator
      def self.prepended(base)
        base.has_many :subscriptions, through: :variants_including_master, source: :subscriptions, dependent: :restrict_with_error
        base.has_many :product_subscription_frequencies, class_name: "Spree::ProductSubscriptionFrequency", dependent: :destroy
        base.has_many :subscription_frequencies, through: :product_subscription_frequencies, dependent: :destroy
        base.validates :subscription_frequencies, presence: true, if: :subscribable?
        base.scope :subscribable, -> { where(is_subscribable: true) }
        base.whitelisted_ransackable_attributes += %w(is_subscribable) if base.respond_to?(:whitelisted_ransackable_attributes)
        base.alias_attribute :subscribable, :is_subscribable
      end

      def self.ransackable_attributes(auth_object = nil)
        default_attributes = defined?(super) ? super : []
        (default_attributes + %w(is_subscribable)).uniq
      end
    end
  end
end

Spree::Product.prepend ::SpreeProductSubscription::Spree::ProductDecorator
