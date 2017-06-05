class Email < ActiveRecord::Base
  belongs_to :subscriber
  belongs_to :donor

  validates :subscriber_id, uniqueness: true
end
