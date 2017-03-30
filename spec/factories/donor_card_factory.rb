FactoryGirl.define do
  factory :stripe_donor_card, class: DonorCard do
    stripe_token { ActiveSupport::TestCase.generate_stripe_card_token }
    is_active true
    email { FactoryGirl.generate(:email) }
    name { FactoryGirl.generate(:name) }
    ip_address "0.0.0.0"
  end

  factory :donor_card, class: DonorCard do
    stripe_token { ActiveSupport::TestCase.generate_stripe_card_token }
    is_active true
    email { FactoryGirl.generate(:email) }
    name { FactoryGirl.generate(:name) }
    ip_address "0.0.0.0"
  end
end
