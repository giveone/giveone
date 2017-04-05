class Activation < ActiveRecord::Base
  ALLOWED_DESCRIPTION_TAGS = %w(b i a br p)

  belongs_to :categories

  scope :is_public, -> { where(is_public: true) }

  audited

  has_attached_file :photo,
    {
      styles: {
        full: {geometry: "960x540>", format: :png},
        medium: {geometry: "480x270>", format: :png},
        thumb: {geometry: "100x100>" , format: :png}
      }
    }.merge(GiveOne::Application.config.paperclip_defaults)

  validates :name, presence: true
  validates :happening_on, presence: true
  validates :slug, uniqueness: { message: "is already used by another Activation", allow_nil: true }
  validates :blurb, presence: true
  validate :editability, on: :update
  validates_attachment :photo, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"] }

  def self.find_by_param(val)
    where(slug: val).first || find(val)
  end

  def self.description_sanitizer
    @description_sanitizer ||= begin
      HTML::WhiteListSanitizer.new.tap { |s|
        s.allowed_tags.reject! { true }
        ALLOWED_DESCRIPTION_TAGS.each { |tag|
          s.allowed_tags << tag
        }
        s
      }
    end
  end

  before_destroy :destroyable?
  def destroyable?
    new_record?
  end

  def to_param
    slug.presence || id.to_s
  end

  def related_activations
    Activation.where(category_id: category_id).where.not(id: id)
  end

  def twitter_or_name
    self.twitter.present? ? "@#{self.twitter}" : self.name
  end

  # TODO could just migrate all of these to be uniform, and add a validation for the protocol
  def url
    u = read_attribute(:url)
    u !~ /\Ahttp/i ? "http://#{u}" : u
  end

  private

  def editability
    true
  end

  before_save :sanitize_fields
  def sanitize_fields
    self.description = Activation.description_sanitizer.sanitize(description.to_s)
  end
end
