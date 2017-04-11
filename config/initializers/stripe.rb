Stripe.api_key = Rails.application.secrets.stripe_secret_key

module Stripe
  def self.logger
    @logger ||= Logger.new("log/stripe.log")
  end
end
