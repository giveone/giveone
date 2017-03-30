class RearrangeDonorsAndNewsletters < ActiveRecord::Migration
  def up
    change_table :donors do |t|
      # Rearrange cols
      t.change :updated_at, :datetime, after: :uncancelled_at
      t.change :created_at, :datetime, after: :uncancelled_at
      t.change :cancelled_at, :datetime, after: :subscriber_id
      t.change :finished_on, :date, after: :subscriber_id
      t.change :started_on, :date, after: :subscriber_id
      t.change :subscriber_id, :integer, after: :id
      t.change :guid, :string, after: :id
    end

    change_table :newsletters do |t|
      # Rearrange cols
      t.change :donor_generated, :text, after: :nonprofit_id
      t.change :donors_sent_at, :datetime, after: :donor_generated
      t.change :subscriber_generated, :text, after: :donor_generated
      t.change :subscribers_sent_at, :datetime, after: :donors_sent_at
    end
  end

  def down
  end
end
