# for testing in the console
class Sandbox
  DONOR_ATTRIBUTES = {
    add_fee:         false
  }

  STRIPE_DONOR_ATTRIBUTES = DONOR_ATTRIBUTES.merge(
    stripe_customer_id: "cus_xxxxxxxxxxxxxx" # a sandbox user
  )

  CARD_ATTRIBUTES = {
    ip_address:      "0.0.0.0",
    email:           Rails.application.secrets.developer_email,
    name:            "User"
  }

  STRIPE_CARD_ATTRIBUTES = {
    stripe_card_id:  "card_xxxxxxxxxxxxxxxxxxxxxxxx"
  }

  def self.get_test_donor(is_stripe = false, add_fee = false)
    d = Donor.new(is_stripe ? STRIPE_DONOR_ATTRIBUTES)
    d.build_card(is_stripe ? STRIPE_CARD_ATTRIBUTES)
    d.add_fee = add_fee
    d.build_subscriber
    d.tap(&:valid?) #trigger validation so Subscriber is created
  end

  def self.get_test_donation(is_stripe = false, add_fee = false)
    donor = get_test_donor(is_stripe, add_fee)
    Donation.new(
      donor: donor,
      donor_card: donor.card,
      nonprofits: Nonprofit.limit(30),
    ).tap { |d|
      d.amount = d.calculate_amount
      d.added_fee = d.calculate_added_fee
    }
  end
end
