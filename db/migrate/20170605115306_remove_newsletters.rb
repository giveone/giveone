class RemoveNewsletters < ActiveRecord::Migration
  def change
    drop_table :newsletters
  end
end
