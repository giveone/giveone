require_relative '../test_helper'

class DonorCardTest < ActiveSupport::TestCase

  context "a new donor" do
    subject do
      FactoryGirl.create(:stripe_donor).card
    end

    should belong_to(:donor)
    should have_many(:donations)

    should allow_value('test@gmail.com').for(:email)
    should_not allow_value("test@gmail").for(:email)
    should_not allow_value('').for(:email)

    should ensure_length_of(:name).is_at_least(2)

    context "creating" do
      setup { subject.donor.save! }

      should_change "DonorCard", by: 1 do DonorCard.count end
    end
  end
  
end
