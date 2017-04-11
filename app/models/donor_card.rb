class DonorCard < ActiveRecord::Base
	belongs_to :donor, inverse_of: :card
  has_many   :donations

  STRIPE_FIELDS = [
    :stripe_token,
    :stripe_email, # Not used right now
    :card_number, :exp_month, :exp_year, :cvc
  ]

  attr_accessor *STRIPE_FIELDS

  audited

  validates :donor, presence: true
  validates :name, presence: true, length: { minimum: 2 }
  validates :email, presence: true, format: { # +email+ is for record-keeping & to simplify the donate form
    with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  }

  scope :active, -> { where(is_active: true) }

  def stripe?; true end # onle Stripe supported for now

  def get_stripe_card_details
    customer = Stripe::Customer.retrieve(donor.stripe_customer_id)
    card = customer.sources.retrieve(self.stripe_card_id)

    # return an array of card details, as strings
    return {
      cc_suffix: card.last4.to_s,
      cc_exp_month: ('%02d' % card.exp_month),
      cc_exp_year: card.exp_year.to_s
    }
  rescue => e
    ExceptionNotifier.notify_exception(e, data: {donor_card_id: self.id})
    nil
  end

  def valid_credentials?(last_4="0000", exp_month="00", exp_year="0000")
    cof = get_stripe_card_details

    return false if cof.blank?
    return false if cof[:cc_suffix]    != last_4.to_s.squish
    return false if cof[:cc_exp_month] != exp_month.to_s.squish
    return false if cof[:cc_exp_year]  != exp_year.to_s.squish

    true
  end

  def activate!
    update!(is_active: true)
  end

  # TODO if this fails and return false, maybe we should update is_active:false
  # anyway? The error will likely be dev/staging errors for CardNotFound.
  def deactivate!
    return true # TODO add deactivate support for true
  end

  private

  validate :create_cof, on: :create
  def create_cof
    if stripe_card_id.present?
      # NO-OP -- already created it from the Donor record
    elsif stripe_token.present? # Adding a new card

      # We always want to be creating Cusomter+Card at same time so we
      # don't have any orphaned Customers if the Card is declined on creation
      if donor.stripe_customer_id.nil?
        customer = Stripe::Customer.create({
          description: self.name,
          source: stripe_token # create the COF while we're at it
        })
        Stripe.logger.info "Stripe::Customer.create\n#{customer.pretty_inspect}\n"

        if donor.new_record?
          donor.stripe_customer_id = customer.id
        else
          donor.update_column(:stripe_customer_id, customer.id)
        end

        card = customer.sources.first
        # check if plan exists first
        plan_id = "#{self.amount}-recurring-plan"
        plan = Stripe::Plan.all.data.find { |plan| plan.id == plan_id } if (Stripe::Plan.all.data.any? { |plan| plan.id == plan_id})

        Stripe.logger.info "Stripe::Plan.create\n#{plan_id}\n" if plan.nil?

        plan ||= Stripe::Plan.create(
          name: "#{self.amount} Recurring Plan",
          id: plan_id,
          interval: "month",
          currency: "usd",
          amount: self.amount.to_i * 100
        )

        subscription = Stripe::Subscription.create(
          customer: customer.id,
          plan: plan_id,
          metadata: {
            donor_id: donor.id,
            donor_card_name: self.name,
            donor_card_email: self.email
          }
        )

        Stripe.logger.info "Stripe::Subscription.create\n#{customer.pretty_inspect}-#{plan_id}\n"
      else # for fixing cards, when Customer already exists
        # UGH tempfix until this issue is fixed in stripe-ruby-mock: https://github.com/rebelidealist/stripe-ruby-mock/issues/209#issuecomment-104020177
        customer = Stripe::Customer.retrieve(donor.stripe_customer_id, {api_key: Stripe.api_key})
        Stripe.logger.info "Stripe::Card.create\n#{card.pretty_inspect}\n"
        # TODO deactivate the old card after this one is active (maybe an "after_activate" callback or something?)
        card = customer.sources.create(source: stripe_token)
      end

      self.stripe_card_id = card.id
    end

    true
  rescue Stripe::CardError => e
    ExceptionNotifier.notify_exception(e)
    Stripe.logger.info "Stripe::CardError: #{e.inspect}\n#{e.json_body}"

    case e.json_body[:error][:param]
    when "cvc"
      errors.add(:cvc, e.json_body[:error][:message])
    when "invalid_expiry_month"
      errors.add(:exp_month, e.json_body[:error][:message])
    when "invalid_expiry_year"
      errors.add(:exp_year, e.json_body[:error][:message])
    when "number"
      errors.add(:card_number, e.json_body[:error][:message])
    else
      errors.add(:base, e.json_body[:error][:message])
    end

    false
  end
end
