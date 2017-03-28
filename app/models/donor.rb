class Donor < ActiveRecord::Base
  belongs_to :subscriber, touch: true # (adding the 'validate' option causes a 2x :guid uniq validation in donor_test???) , validate: true # inseparable from the donor -- don't delete or detach
  has_many   :donations

  has_many   :cards, class_name: 'DonorCard'
  has_one    :card, -> { DonorCard.active }, class_name: 'DonorCard', inverse_of: :donor

  has_many   :nonprofits_donated_to,
             -> { order(featured_on: :desc) },
             through: :donations,
             source: :donated_nonprofits

  accepts_nested_attributes_for :card
  accepts_nested_attributes_for :subscriber

  validates :subscriber, uniqueness: true, presence: true
  validates :guid, uniqueness: true, if: :guid_changed?

  scope :active,    -> { where(finished_on: nil, failed_at: nil) }
  scope :inactive,  -> { where("finished_on <= ? OR failed_at IS NOT NULL", Date.today) }
  scope :cancelled, -> { where.not(cancelled_at: nil) }
  scope :failed,    -> { where.not(failed_at: nil) }
  # should be mutually exclusive from Subscriber#for_daily_newsletter
  scope :for_daily_newsletter, -> { active.subscribed }
  scope :subscribed,        -> { joins(:subscriber).merge(Subscriber.active) }
  scope :unsubscribed,      -> { joins(:subscriber).merge(Subscriber.inactive) }
  scope :with_public_names, -> { where.not(public_name: ["", nil]) }

  STRIPE_FIELDS = [
    :stripe_token
  ]

  attr_accessor *STRIPE_FIELDS

  audited

  def stripe?; stripe_customer_id.present?; end

  # # Get all the donors that have a donation to this nonprofit
  scope :for_nonprofit, ->(n) {
    joins(donations: [:nonprofits]).where("nonprofits.id = ?", n.id)
  }


  def to_param
    subscriber.try(:guid)
  end

  def has_duplicates?
    nonprofit_ids = donations.flat_map { |d| d.donation_nonprofits.pluck(:nonprofit_id) }
    nonprofit_ids.size != nonprofit_ids.uniq.size
  end

  def self.check_for_duplicate_donations
    donor_ids = Donor.all.select(&:has_duplicates?).map(&:id)
    AdminMailer.duplicate_donations(donor_ids).deliver if donor_ids.present?
  end

  def self.find_by_param(val)
    where(id: val).first || find(val)
  end

  # Regularly check/nullify donors who have left their active period (>30 days
  # after their last charge, aka after their last daily $1 donation).
  def self.finish_cancelled_donors
    Donor.active.cancelled.each do |donor|
      last_donation = donor.last_executed_donation
      if last_donation.blank? || Time.now > (last_donation.scheduled_at + 30.days)
        donor.card.try(:deactivate!)
        donor.update_attribute(:finished_on, Time.zone.now.to_date)
      end
    end
  end

  def active_subscriber?
    subscriber.try(:active?)
  end

  def cancelled?
    cancelled_at.present?
  end

  def active?
    !inactive?
  end

  def failed?
    failed_at.present?
  end

  def inactive?
    failed? || finished_on.present?
  end

  def last_executed_donation
    donations.executed.order("executed_at DESC").first
  end

  def cancel!(notify_donor: true)
    return if cancelled?

    transaction do
      donations.pending.update_all(cancelled_at: Time.now)
      self.cancelled_at = Time.now
      self.uncancelled_at = nil
      save!
      SendCancelledJob.new(self.id).save if notify_donor
    end
  end

  def uncancel!
    return unless cancelled?

    transaction do
      last_donation = donations.executed.last
      next_donation_at = [
        (30.days.since(last_donation.scheduled_at) if last_donation), # for cancelled/active donors
        finished_on,  # for cancelled/inactive donors (this *should* actually be the same as the above, if finished_on is present)
        Time.now      # bare minimum
      ].compact.max

      # NB schedule at 12am, so the newsletter at 8am has the day's correct donor count
      donations.build(scheduled_at: next_donation_at.beginning_of_day)
      self.uncancelled_at = Time.now
      self.finished_on  = nil
      self.cancelled_at = nil
      save!
      SendUncancelledJob.new(self.id).save
    end
  end

  private

  after_create :schedule_first_donation
  def schedule_first_donation
    donations.create(scheduled_at: Time.now)
  end

  before_validation :preprocess, on: :create
  def preprocess
    self.started_on                 = Time.zone.now.to_date
    self.guid                       = guid.presence || SecureRandom.hex(16)
    if s = Subscriber.without_donor.where(email: card.email).first
      self.subscriber = s
    end

    build_subscriber if subscriber.blank?

    subscriber.name                 = card.name       if subscriber.name.blank? # populate the subscriber's name (means they existed already)
    subscriber.email                = card.email      if subscriber.email.blank?
    subscriber.ip_address           = card.ip_address if subscriber.ip_address.blank?
  end
end
