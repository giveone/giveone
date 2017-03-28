require_relative '../test_helper'

class DonationTest < ActiveSupport::TestCase
  subject { Donation.new(donor: FactoryGirl.build(:stripe_donor), guid: "asdf") }

  should belong_to(:donor)
  should belong_to(:donor_card)
  should have_many(:donation_nonprofits)
  should have_many(:nonprofits).through(:donation_nonprofits)

  should validate_presence_of(:scheduled_at)
  should "validate uniqueness of guid" do
    existing_donation = FactoryGirl.create(:scheduled_donation, guid: subject.guid)
    assert !subject.valid?
    assert_equal ["has already been taken"], subject.errors[:guid]
  end

  context "a Stripe donation" do
    setup do
      @donation = FactoryGirl.create(:scheduled_donation, donor: FactoryGirl.build(:stripe_donor))
    end

    context "locking and executing" do
      setup { @donation.lock_and_execute! }

      should_delay_job "ExecuteDonationJob"
      should_change "lock", from: nil do @donation.locked_at end
    end

    context "executing" do
      setup do
        @donation.execute!
      end

      should_change "stripe_charge_id", from: nil, to: /test_ch_\d/ do @donation.reload.stripe_charge_id end
      should_change "donation's nonprofits", from: 0, to: 30 do
        @donation.nonprofits(true).count
      end
      should "set donation's nonprofits correctly" do
        assert_equal @donation.nonprofits, @donation.scheduled_nonprofits
      end
      should "set donation's donation_nonprofits' dates" do
        assert_equal @donation.donation_nonprofits(true).map(&:donation_on), @donation.nonprofits.map(&:featured_on)
      end
      should_change "donation's amount", from: 0.0, to: 30.0 do @donation.reload.amount.to_f end
      should_not_change "donation's added_fee" do @donation.reload.added_fee.to_f end
      should_change "executed_at" do @donation.reload.executed_at end
    end

    context "executing with added fee" do
      setup do
        @donation.donor.update_column(:add_fee, true)
        @donation.reload
        @donation.execute!
      end

      should_change "stripe_charge_id", from: nil, to: /test_ch_\d/ do @donation.reload.stripe_charge_id end
      should_change "donation's nonprofits", from: 0.0, to: 30 do @donation.nonprofits(true).count end
      should_change "donation's amount", from: 0.0, to: 30.0 do @donation.reload.amount.to_f end
      should_change "donation's added_fee", from: 0.0, to: 1.20 do @donation.reload.added_fee.to_f end
      should_change "executed_at" do @donation.reload.executed_at end

      # NB this is mostly a sanity check to make sure our calculation scales up
      context "calculating fee for a $60 donation" do
        setup { @donation.stubs(:calculate_amount).returns(60.0) }
        should "return correct fee" do assert_equal 2.10, @donation.calculate_added_fee.round(2) end
      end

      context "calculating fee for a $120 donation" do
        setup { @donation.stubs(:calculate_amount).returns(120.0) }
        should "return correct fee" do assert_equal 3.89, @donation.calculate_added_fee.round(2) end
      end

      context "calculating fee for a $1000 donation" do
        setup { @donation.stubs(:calculate_amount).returns(1000.0) }
        should "return correct fee" do assert_equal 30.18, @donation.calculate_added_fee.round(2) end
      end
    end

    context "executing and getting a card error" do
      setup do
        StripeMock.prepare_card_error(:card_declined)
        @donation.expects(:fail!)
      end

      should "raise error" do
        @donation.execute!
        @donation.reload

        assert_equal nil, @donation.stripe_charge_id
        assert_equal 30, @donation.nonprofits(true).count
        assert_equal 0.0, @donation.amount.to_f
        assert_equal 0.0, @donation.added_fee.to_f
        assert_nil @donation.executed_at
      end
    end
  end


end
