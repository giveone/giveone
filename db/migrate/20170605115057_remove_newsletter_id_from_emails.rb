class RemoveNewsletterIdFromEmails < ActiveRecord::Migration
  def change
    remove_column :emails, :newsletter_id, :integer
  end
end
