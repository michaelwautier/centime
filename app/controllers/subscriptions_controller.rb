class SubscriptionsController < ApplicationController
  def show
    @entitlements = Entitlements.new(current_user)
  end

  def checkout
    current_user.set_payment_processor(:stripe)
    session = current_user.payment_processor.checkout(
      mode: "subscription",
      line_items: [ { price: ENV.fetch("STRIPE_PRO_PRICE_ID"), quantity: 1 } ],
      success_url: success_subscription_url,
      cancel_url: subscription_url
    )
    redirect_to session.url, allow_other_host: true, status: :see_other
  end

  def success
    redirect_to subscription_path, notice: "Welcome to Centime Pro! You can now connect multiple banks."
  end

  def billing_portal
    portal = current_user.payment_processor.billing_portal(return_url: subscription_url)
    redirect_to portal.url, allow_other_host: true, status: :see_other
  end
end
