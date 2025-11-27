module SpreeProductSubscription
  module Spree
    module OrderDecorator
      def self.prepended(base)
        base.has_one :order_subscription, class_name: "Spree::OrderSubscription", dependent: :destroy
        base.has_one :parent_subscription, through: :order_subscription, source: :subscription
        base.has_many :subscriptions, class_name: "Spree::Subscription",
                                      foreign_key: :parent_order_id,
                                      dependent: :restrict_with_error

        base.after_update :update_subscriptions
        base.after_commit :enable_subscriptions_after_complete, on: :update
        base.alias_attribute :guest_token, :token
      end

      # def available_payment_methods
      #   if subscriptions.exists?
      #     @available_payment_methods = Spree::Gateway.active.available_on_front_end
      #   else
      #     @available_payment_methods ||= Spree::PaymentMethod.active.available_on_front_end
      #   end
      # end  

      private

      def enable_subscriptions
        payment_source = most_recent_payment_source

        unless payment_source
          Rails.logger.warn("[Subscriptions] Unable to enable subscriptions for order #{number}: no valid payment source found")
          return
        end

        subscriptions.disabled.each do |subscription|
          subscription.update(
            source: payment_source,
            enabled: true,
            ship_address: ship_address.clone,
            bill_address: bill_address.clone
          )
        end
      end

      def enable_subscriptions_after_complete
        return unless previous_changes.key?('state')
        return unless state == 'complete'
        return unless any_disabled_subscription?

        enable_subscriptions
      end

      def any_disabled_subscription?
        subscriptions.disabled.any?
      end

      def update_subscriptions
        line_items.each do |line_item|
          if line_item.subscription_attributes_present?
            subscriptions.find_by(variant: line_item.variant).update(line_item.updatable_subscription_attributes)
          end
        end
      end

      def most_recent_payment_source
        payments.valid.order(created_at: :desc).detect(&:source)&.source
      end
    end
  end
end

::Spree::Order.prepend ::SpreeProductSubscription::Spree::OrderDecorator
