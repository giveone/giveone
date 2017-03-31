STRIPE = {
  secret_key: Rails.application.secrets.stripe_secret_key,
  publishable_key: Rails.application.secrets.stripe_publishable_key,
  account_id: Rails.application.secrets.stripe_account_id
}

Stripe.api_key = STRIPE[:secret_key]

module Stripe
  def self.logger
    @logger ||= Logger.new("log/stripe.log")
  end
end
