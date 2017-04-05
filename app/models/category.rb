class Category < ActiveRecord::Base
  ALLOWED_DESCRIPTION_TAGS = %w(b i a br p)

  has_many :nonprofits
  has_many :activations

  audited

  validates :name, presence: true
  validates :slug, uniqueness: { message: "is already used by another Category", allow_nil: true }
  validate :editability, on: :update

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

  def editability
    true
  end

  before_save :sanitize_fields
  def sanitize_fields
    self.description = Category.description_sanitizer.sanitize(description.to_s)
  end
end
