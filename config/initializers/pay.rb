Pay.setup do |config|
  config.application_name = "Centime"
  config.business_name = "Centime"
  config.support_email = "support@centime.example"
  config.default_product_name = "Centime Pro"
  config.default_plan_name = "pro"
end

# Stripe tells us a subscription ended (cancellation, failed payments, …):
# free-plan limits apply again.
ActiveSupport.on_load(:pay) do
  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.deleted" do |event|
    pay_customer = Pay::Customer.find_by(processor: :stripe, processor_id: event.data.object.customer)
    Billing::HandleDowngrade.call(user: pay_customer.owner) if pay_customer&.owner
  end
end
