class AddIndexToCategorySlug < ActiveRecord::Migration
  def up
    add_index :categories, :slug
  end

  def down
    remove_index :categories, :slug
  end
end
