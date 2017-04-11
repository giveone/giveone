class Subscriber < ActiveRecord::Base
  has_one  :donor # inseparable from the subscriber -- don't delete or deatch
  has_many :emails

  validates :email, presence: true, uniqueness: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9\*]+\.)+[a-z]{2,})\Z/i }
  validates :name, length: { minimum: 1, maximum: 100, allow_blank: true }
  validates :auth_token, presence: true, uniqueness: true
  validates :ip_address, presence: true
  validates :name, presence: true

  scope :active,   -> { where(unsubscribed_at: nil) }
  scope :inactive, -> { where.not(unsubscribed_at: nil) }

  # should be mutually exclusive from Donor#for_daily_newsletter
  scope :for_daily_newsletter, -> {
    active.
    joins("LEFT JOIN donors ON subscribers.id = donors.subscriber_id").
    where("donors.id IS NULL OR donors.finished_on < ?", Time.now).
    where("donors.failed_at IS NULL") # don't send *any* newsletters to failed donors
  }
  scope :without_donor, -> {
    joins("LEFT JOIN donors ON subscribers.id = donors.subscriber_id").
    where(donors: {id: nil})
  }

  accepts_nested_attributes_for :donor, update_only: true

  audited

  attr_accessor :resubscribing

  def active?
    unsubscribed_at.blank?
  end

  def active_donor?
    donor.try(:active?)
  end

  def never_subscribed?
    subscribed_at && unsubscribed_at && subscribed_at.change(sec: 0) == unsubscribed_at.change(sec: 0)
  end

  def to_param
    guid
  end

  def donor?
    donor.present?
  end

  def first_name
    name.to_s.split_name.first
  end

  def unsubscribe!
    self.unsubscribed_at = Time.now
    save!
  end

  def resubscribe!
    self.unsubscribed_at = nil
    self.subscribed_at = Time.now
    save!
    SendFirstNewsletterJob.new(self.id).save
  end

  def set_location
    return if ip_address == "127.0.0.1"

    ip_address = ip_address.gsub(/[^0-9.]/, '')
    # @TODO: do this via Mailchimp DMITRI
    self.save!
  end

  def to_mandrill_recipient
    return { self.email => self.slice(:guid, :auth_token).merge(name: self.first_name) }
  end

  after_commit :update_intercom
  def update_intercom
    SyncSubscriberDataToIntercomJob.new(self.id).save
  end

  private

  # Preprocess
  before_validation :preprocess, on: :create
  def preprocess
    self.subscribed_at       = Time.now
    self.guid              ||= SecureRandom.hex(16)
    self.auth_token        ||= SecureRandom.hex(32)
    true
  end

  after_create :send_first_newsletter
  def send_first_newsletter
    SendFirstNewsletterJob.new(self.id).save if active?
  end

  after_create :lookup_location
  def lookup_location
    SetSubscriberLocationJob.new(id).save if ip_address.present?
  end

  after_update :send_email_changed_notification, if: :email_changed?
  def send_email_changed_notification
    SendEmailChangedNotificationJob.new(id, email, email_was).save
  end
end
